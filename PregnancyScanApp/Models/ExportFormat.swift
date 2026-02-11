import Foundation

enum ExportFormat: String, CaseIterable, Identifiable {
    case usdz
    case obj
    case stl

    var id: String { rawValue }

    var fileExtension: String { rawValue }

    var displayName: String {
        switch self {
        case .usdz: return "USDZ"
        case .obj: return "OBJ"
        case .stl: return "STL"
        }
    }

    var description: String {
        switch self {
        case .usdz: return "Universal Scene Description (AR viewing)"
        case .obj: return "Wavefront OBJ (3D editing & printing)"
        case .stl: return "Stereolithography (3D printing standard)"
        }
    }

    var iconName: String {
        switch self {
        case .usdz: return "arkit"
        case .obj: return "cube.transparent"
        case .stl: return "printer.fill"
        }
    }

    func fileName(base: String = AppConstants.modelFileName) -> String {
        "\(base).\(fileExtension)"
    }
}
