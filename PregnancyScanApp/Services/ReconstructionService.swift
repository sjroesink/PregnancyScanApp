import RealityKit
import Foundation

#if canImport(ObjectCapture)
import ObjectCapture
typealias AppPhotogrammetrySession = ObjectCapture.PhotogrammetrySession
#else
typealias AppPhotogrammetrySession = RealityKit.PhotogrammetrySession
#endif

@Observable
@MainActor
final class ReconstructionService {

    private(set) var progress: Float = 0.0
    private(set) var estimatedTimeRemaining: TimeInterval?
    private(set) var currentStage: String = "Preparing..."
    private(set) var isProcessing = false
    private(set) var isComplete = false
    private(set) var outputModelURL: URL?

    private var processingTask: Task<Void, Never>?

    func reconstruct(
        imagesDirectory: URL,
        outputModelURL: URL,
        checkpointDirectory: URL?
    ) async throws {
        isProcessing = true
        isComplete = false
        progress = 0.0
        currentStage = "Initializing..."

        var configuration = AppPhotogrammetrySession.Configuration()

        if let checkpointDir = checkpointDirectory {
            configuration.checkpointDirectory = checkpointDir
        }

        configuration.featureSensitivity = .high
        configuration.isObjectMaskingEnabled = true
        configuration.sampleOrdering = .unordered

        let session = try AppPhotogrammetrySession(
            input: imagesDirectory,
            configuration: configuration
        )

        let request = AppPhotogrammetrySession.Request.modelFile(url: outputModelURL)
        try session.process(requests: [request])

        for try await output in session.outputs {
            switch output {
            case .processingComplete:
                self.isComplete = true
                self.isProcessing = false
                self.outputModelURL = outputModelURL
                self.progress = 1.0
                self.currentStage = "Complete"

            case .requestProgress(_, let fractionComplete):
                self.progress = Float(fractionComplete)

            case .requestProgressInfo(_, let progressInfo):
                self.estimatedTimeRemaining = progressInfo.estimatedRemainingTime

            case .requestComplete(_, let result):
                switch result {
                case .modelFile(let url):
                    self.outputModelURL = url
                default:
                    break
                }

            case .requestError(_, let error):
                self.isProcessing = false
                throw error

            case .processingCancelled:
                self.isProcessing = false
                return

            case .inputComplete:
                self.currentStage = "Processing images..."

            case .invalidSample(let id, let reason):
                // Skip invalid samples silently
                break

            case .skippedSample(let id):
                break

            case .automaticDownsampling:
                self.currentStage = "Downsampling for device..."

            case .stitchingIncomplete:
                break
            @unknown default:
                break
            }
        }
    }

    func cancel() {
        processingTask?.cancel()
        processingTask = nil
        isProcessing = false
    }

    var formattedTimeRemaining: String? {
        guard let time = estimatedTimeRemaining, time > 0 else { return nil }

        let minutes = Int(time) / 60
        let seconds = Int(time) % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s remaining"
        } else {
            return "\(seconds)s remaining"
        }
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }
}
