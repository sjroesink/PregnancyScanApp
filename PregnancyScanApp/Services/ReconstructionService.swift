import RealityKit
import Foundation

@available(iOS 17.0, *)
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

    enum ReconstructionError: LocalizedError {
        case reconstructionFailed

        var errorDescription: String? {
            switch self {
            case .reconstructionFailed:
                return "3D reconstruction failed."
            }
        }
    }

    func reconstruct(
        imagesDirectory: URL,
        outputModelURL: URL,
        checkpointDirectory: URL?
    ) async throws {
        isProcessing = true
        isComplete = false
        progress = 0.0
        currentStage = "Initializing..."

        var configuration = PhotogrammetrySession.Configuration()

        if let checkpointDir = checkpointDirectory {
            configuration.checkpointDirectory = checkpointDir
        }

        configuration.featureSensitivity = .high
        configuration.isObjectMaskingEnabled = true
        configuration.sampleOrdering = .unordered

        let session = try PhotogrammetrySession(
            input: imagesDirectory,
            configuration: configuration
        )

        let request = PhotogrammetrySession.Request.modelFile(url: outputModelURL)
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

            case .invalidSample(_, _):
                break

            case .skippedSample(_):
                break

            case .automaticDownsampling:
                self.currentStage = "Downsampling for device..."

            default:
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
