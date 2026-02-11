import RealityKit
import ARKit
import Combine

@Observable
@MainActor
final class CaptureSessionService {

    // MARK: - Scan Height System

    enum ScanHeight: Int, CaseIterable, Identifiable {
        case low = 0
        case mid = 1
        case high = 2

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .low: return AppConstants.ScanPassGuidance.lowPassTitle
            case .mid: return AppConstants.ScanPassGuidance.midPassTitle
            case .high: return AppConstants.ScanPassGuidance.highPassTitle
            }
        }

        var guidance: String {
            switch self {
            case .low: return AppConstants.ScanPassGuidance.lowPassDescription
            case .mid: return AppConstants.ScanPassGuidance.midPassDescription
            case .high: return AppConstants.ScanPassGuidance.highPassDescription
            }
        }

        var passNumber: Int { rawValue + 1 }
    }

    // MARK: - State

    #if !targetEnvironment(simulator)
    private(set) var objectCaptureSession: ObjectCaptureSession?
    #endif
    private(set) var currentScanHeight: ScanHeight = .low
    private(set) var completedPasses: Set<ScanHeight> = []
    private(set) var numberOfShotsTaken: Int = 0
    private(set) var userGuidance: String = ""
    private(set) var canRequestModelOutput: Bool = false
    private(set) var isPaused: Bool = false

    private var stateObservationTask: Task<Void, Never>?
    private var feedbackObservationTask: Task<Void, Never>?

    // MARK: - Errors

    enum CaptureError: LocalizedError {
        case deviceNotSupported
        case sessionCreationFailed

        var errorDescription: String? {
            switch self {
            case .deviceNotSupported:
                return "This device does not support Object Capture."
            case .sessionCreationFailed:
                return "Failed to create capture session."
            }
        }
    }

    // MARK: - Session Lifecycle

    func startSession(imagesDirectory: URL, snapshotsDirectory: URL) throws {
        #if !targetEnvironment(simulator)
        guard ObjectCaptureSession.isSupported else {
            throw CaptureError.deviceNotSupported
        }

        let session = ObjectCaptureSession()

        var configuration = ObjectCaptureSession.Configuration()
        configuration.checkpointDirectory = snapshotsDirectory
        configuration.isOverCaptureEnabled = true

        session.start(
            imagesDirectory: imagesDirectory,
            configuration: configuration
        )

        self.objectCaptureSession = session
        self.currentScanHeight = .low
        self.completedPasses = []
        self.numberOfShotsTaken = 0

        observeState()
        observeFeedback()
        #else
        throw CaptureError.deviceNotSupported
        #endif
    }

    func startDetecting() {
        #if !targetEnvironment(simulator)
        objectCaptureSession?.startDetecting()
        #endif
    }

    func startCapturing() {
        #if !targetEnvironment(simulator)
        objectCaptureSession?.startCapturing()
        #endif
    }

    func beginNextPass() {
        completedPasses.insert(currentScanHeight)

        if let nextHeight = ScanHeight(rawValue: currentScanHeight.rawValue + 1) {
            #if !targetEnvironment(simulator)
            objectCaptureSession?.beginNewScanPass()
            #endif
            currentScanHeight = nextHeight
        }
    }

    func finishCapture() {
        completedPasses.insert(currentScanHeight)
        #if !targetEnvironment(simulator)
        objectCaptureSession?.finish()
        #endif
    }

    func pauseCapture() {
        #if !targetEnvironment(simulator)
        objectCaptureSession?.pause()
        #endif
        isPaused = true
    }

    func resumeCapture() {
        #if !targetEnvironment(simulator)
        objectCaptureSession?.resume()
        #endif
        isPaused = false
    }

    func cancelSession() {
        #if !targetEnvironment(simulator)
        objectCaptureSession?.cancel()
        #endif
        cleanup()
    }

    // MARK: - Observation

    private func observeState() {
        #if !targetEnvironment(simulator)
        stateObservationTask?.cancel()
        stateObservationTask = Task { [weak self] in
            guard let session = self?.objectCaptureSession else { return }
            for await newState in session.stateUpdates {
                guard !Task.isCancelled else { return }
                await self?.handleStateUpdate(newState)
            }
        }
        #endif
    }

    private func observeFeedback() {
        #if !targetEnvironment(simulator)
        feedbackObservationTask?.cancel()
        feedbackObservationTask = Task { [weak self] in
            guard let session = self?.objectCaptureSession else { return }
            for await feedback in session.feedbackUpdates {
                guard !Task.isCancelled else { return }
                await self?.handleFeedback(feedback)
            }
        }
        #endif
    }

    #if !targetEnvironment(simulator)
    private func handleStateUpdate(_ state: ObjectCaptureSession.CaptureState) {
        switch state {
        case .ready:
            userGuidance = "Position yourself to start scanning"
        case .detecting:
            userGuidance = "Detecting subject..."
        case .capturing:
            userGuidance = currentScanHeight.guidance
        case .finishing:
            userGuidance = "Finishing capture..."
        case .completed:
            userGuidance = "Capture complete!"
            canRequestModelOutput = true
        case .failed(let error):
            userGuidance = "Capture failed: \(error.localizedDescription)"
        @unknown default:
            break
        }
    }

    private func handleFeedback(_ feedback: Set<ObjectCaptureSession.Feedback>) {
        if feedback.contains(.objectTooClose) {
            userGuidance = "Move further from the subject"
        } else if feedback.contains(.objectTooFar) {
            userGuidance = "Move closer to the subject"
        } else if feedback.contains(.movingTooFast) {
            userGuidance = "Slow down your movement"
        } else if feedback.contains(.environmentTooDark) {
            userGuidance = "More light is needed"
        } else if feedback.contains(.environmentLowLight) {
            userGuidance = "Consider adding more light"
        } else if feedback.contains(.outOfFieldOfView) {
            userGuidance = "Point camera at the subject"
        } else if feedback.isEmpty {
            userGuidance = currentScanHeight.guidance
        }

        if let session = objectCaptureSession {
            numberOfShotsTaken = session.numberOfShotsTaken
        }
    }
    #endif

    private func cleanup() {
        stateObservationTask?.cancel()
        feedbackObservationTask?.cancel()
        stateObservationTask = nil
        feedbackObservationTask = nil
        #if !targetEnvironment(simulator)
        objectCaptureSession = nil
        #endif
        isPaused = false
    }

    deinit {
        stateObservationTask?.cancel()
        feedbackObservationTask?.cancel()
    }
}
