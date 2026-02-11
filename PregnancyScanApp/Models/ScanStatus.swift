import Foundation

enum ScanStatus: String, Codable, CaseIterable {
    case preparing
    case capturing
    case reconstructing
    case completed
    case failed

    var displayName: String {
        switch self {
        case .preparing: return "Preparing"
        case .capturing: return "Capturing"
        case .reconstructing: return "Reconstructing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    var iconName: String {
        switch self {
        case .preparing: return "gear"
        case .capturing: return "camera.viewfinder"
        case .reconstructing: return "gearshape.2"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    var isTerminal: Bool {
        self == .completed || self == .failed
    }
}
