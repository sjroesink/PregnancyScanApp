import SwiftUI
import SwiftData
import RealityKit

@available(iOS 17.0, *)
@Observable
@MainActor
final class ScanSessionViewModel {

    let captureService = CaptureSessionService()
    let fileManagerService = FileManagerService()

    private(set) var scanPaths: FileManagerService.ScanFolderPaths?
    private(set) var scanRecord: ScanRecord?
    private(set) var showPointCloudPreview = false
    var showPassCompleteSheet = false
    private(set) var isSessionActive = false
    private(set) var countdownValue: Int = 0
    private(set) var isCountingDown = false

    #if ENABLE_OBJECT_CAPTURE
    var session: ObjectCaptureSession? { captureService.objectCaptureSession }
    #endif
    var currentHeight: CaptureSessionService.ScanHeight { captureService.currentScanHeight }
    var completedPasses: Set<CaptureSessionService.ScanHeight> { captureService.completedPasses }
    var imageCount: Int { captureService.numberOfShotsTaken }
    var guidanceText: String { captureService.userGuidance }
    var canFinish: Bool { captureService.canRequestModelOutput || imageCount >= AppConstants.minimumRecommendedImages }

    var isLastPass: Bool {
        currentHeight == .high
    }

    var passProgressText: String {
        "Pass \(currentHeight.passNumber) of \(AppConstants.scanPassCount)"
    }

    // MARK: - Session Management

    func startNewScan(context: ModelContext) async throws {
        let paths = try fileManagerService.createScanFolder()
        self.scanPaths = paths

        let relativePath = fileManagerService.relativePath(for: paths.root)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let name = "Scan \(formatter.string(from: Date()))"

        let record = ScanRecord(name: name, scanFolderPath: relativePath)
        record.status = .capturing
        context.insert(record)
        try context.save()
        self.scanRecord = record

        try captureService.startSession(
            imagesDirectory: paths.images,
            snapshotsDirectory: paths.snapshots
        )
        isSessionActive = true
    }

    func startDetecting() {
        captureService.startDetecting()
    }

    func startCapturing() {
        captureService.startCapturing()
    }

    func startCountdownThenCapture() {
        isCountingDown = true
        countdownValue = 3

        Task {
            for i in stride(from: 3, through: 1, by: -1) {
                countdownValue = i
                try? await Task.sleep(for: .seconds(1))
            }
            isCountingDown = false
            countdownValue = 0
            startCapturing()
        }
    }

    func togglePointCloudPreview() {
        showPointCloudPreview.toggle()
    }

    func completeCurrentPass() {
        if isLastPass {
            finishCapture()
        } else {
            showPassCompleteSheet = true
        }
    }

    func advanceToNextPass() {
        showPassCompleteSheet = false
        captureService.beginNextPass()
    }

    func finishCapture() {
        showPassCompleteSheet = false
        captureService.finishCapture()
        updateRecordImageCount()
    }

    func cancelScan() {
        captureService.cancelSession()
        isSessionActive = false
    }

    // MARK: - Record Updates

    private func updateRecordImageCount() {
        guard let paths = scanPaths else { return }
        scanRecord?.imageCount = fileManagerService.imageCount(in: paths.images)
    }

    func updateRecordForReconstruction() {
        scanRecord?.status = .reconstructing
    }

    func updateRecordCompleted(usdzRelativePath: String) {
        scanRecord?.status = .completed
        scanRecord?.modelUSDZPath = usdzRelativePath
    }

    func updateRecordFailed() {
        scanRecord?.status = .failed
    }
}
