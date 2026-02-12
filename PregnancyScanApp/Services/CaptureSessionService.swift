import RealityKit
import ARKit
import Combine
import Observation

#if os(iOS) && ENABLE_OBJECT_CAPTURE
import RealityKit

/// A non-observable wrapper to hold the ObjectCaptureSession.
/// This prevents the @Observable macro in the main service from trying to process
/// the ObjectCaptureSession type, which can fail on some CI environments.
@MainActor
final class CaptureSessionWrapper {
    var session: ObjectCaptureSession?
}
#endif

@available(iOS 17.0, *)
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

    #if os(iOS) && ENABLE_OBJECT_CAPTURE
    @ObservationIgnored
    private let wrapper = CaptureSessionWrapper()
    var objectCaptureSession: ObjectCaptureSession? { wrapper.session }
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
        #if os(iOS) && ENABLE_OBJECT_CAPTURE
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

        self.wrapper.session = session
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
        #if os(iOS) && ENABLE_OBJECT_CAPTURE
        objectCaptureSession?.startDetecting()
        #endif
    }

    func startCapturing() {
        #if os(iOS) && ENABLE_OBJECT_CAPTURE
        objectCaptureSession?.startCapturing()
        #endif
    }

    func beginNextPass() {
        completedPasses.insert(currentScanHeight)

        #if os(iOS) && ENABLE_OBJECT_CAPTURE
        if let nextHeight = ScanHeight(rawValue: currentScanHeight.rawValue + 1) {
            objectCaptureSession?.beginNewScanPass()
            currentScanHeight = nextHeight
        }
        #endif
    }

    func finishCapture() {
        completedPasses.insert(currentScanHeight)
        #if os(iOS) && ENABLE_OBJECT_CAPTURE
        objectCaptureSession?.finish()
        #endif
    }

    func pauseCapture() {
        #if os(iOS) && ENABLE_OBJECT_CAPTURE
        objectCaptureSession?.pause()
        #endif
        isPaused = true
    }

    func resumeCapture() {
        #if os(iOS) && ENABLE_OBJECT_CAPTURE
        objectCaptureSession?.resume()
        #endif
        isPaused = false
    }

    func cancelSession() {
        #if os(iOS) && ENABLE_OBJECT_CAPTURE
        objectCaptureSession?.cancel()
        #endif
        cleanup()
    }

    // MARK: - Observation

    private func observeState() {
        #if os(iOS) && ENABLE_OBJECT_CAPTURE
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
        #if os(iOS) && ENABLE_OBJECT_CAPTURE
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

    #if os(iOS) && ENABLE_OBJECT_CAPTURE
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
        #if os(iOS) && ENABLE_OBJECT_CAPTURE
        stateObservationTask?.cancel()
        feedbackObservationTask?.cancel()
        stateObservationTask = nil
        feedbackObservationTask = nil
        wrapper.session = nil
        #endif
        isPaused = false
    }

    deinit {
    }
}

#else

// MARK: - Simulator Stub

@available(iOS 17.0, *)
@Observable
@MainActor
final class CaptureSessionService {

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

    private(set) var currentScanHeight: ScanHeight = .low
    private(set) var completedPasses: Set<ScanHeight> = []
    private(set) var numberOfShotsTaken: Int = 0
    private(set) var userGuidance: String = ""
    private(set) var canRequestModelOutput: Bool = false
    private(set) var isPaused: Bool = false

    func startSession(imagesDirectory: URL, snapshotsDirectory: URL) throws {
        throw CaptureError.deviceNotSupported
    }
    func startDetecting() {}
    func startCapturing() {}
    func beginNextPass() {}
    func finishCapture() {}
    func pauseCapture() {}
    func resumeCapture() {}
    func cancelSession() {}
}

#endif
