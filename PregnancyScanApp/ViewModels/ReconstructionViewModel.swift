#if ENABLE_OBJECT_CAPTURE
import SwiftUI
import SwiftData

@available(iOS 17.0, *)
@Observable
@MainActor
final class ReconstructionViewModel {

    let reconstructionService = ReconstructionService()
    let fileManagerService = FileManagerService()

    private(set) var scanRecord: ScanRecord?
    private(set) var error: String?

    var progress: Float { reconstructionService.progress }
    var currentStage: String { reconstructionService.currentStage }
    var isProcessing: Bool { reconstructionService.isProcessing }
    var isComplete: Bool { reconstructionService.isComplete }
    var formattedTimeRemaining: String? { reconstructionService.formattedTimeRemaining }
    var progressPercentage: Int { reconstructionService.progressPercentage }

    func loadRecord(id: UUID, context: ModelContext) {
        let descriptor = FetchDescriptor<ScanRecord>(
            predicate: #Predicate<ScanRecord> { $0.id == id }
        )
        scanRecord = try? context.fetch(descriptor).first
    }

    func startReconstruction(context: ModelContext) async {
        guard let record = scanRecord else {
            error = "No scan record found"
            return
        }

        let imagesDirectory = record.imagesDirectoryURL
        let modelsDirectory = record.modelsDirectoryURL
        let snapshotsDirectory = record.snapshotsDirectoryURL
        let outputURL = modelsDirectory.appending(
            path: ExportFormat.usdz.fileName()
        )

        record.status = .reconstructing
        try? context.save()

        do {
            try await reconstructionService.reconstruct(
                imagesDirectory: imagesDirectory,
                outputModelURL: outputURL,
                checkpointDirectory: snapshotsDirectory
            )

            let relativePath = fileManagerService.relativePath(for: outputURL)
            record.status = .completed
            record.modelUSDZPath = relativePath
            try? context.save()

        } catch {
            record.status = .failed
            try? context.save()
            self.error = error.localizedDescription
        }
    }

    func cancelReconstruction() {
        reconstructionService.cancel()
        scanRecord?.status = .failed
    }
}
#endif
