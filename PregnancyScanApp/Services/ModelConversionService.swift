import ModelIO
import Foundation

final class ModelConversionService {

    enum ConversionError: LocalizedError {
        case formatNotSupported(String)
        case exportFailed(String)
        case loadFailed(URL)

        var errorDescription: String? {
            switch self {
            case .formatNotSupported(let fmt):
                return "Export format '\(fmt)' is not supported on this device."
            case .exportFailed(let detail):
                return "Export failed: \(detail)"
            case .loadFailed(let url):
                return "Failed to load model from \(url.lastPathComponent)"
            }
        }
    }

    func convertToOBJ(from sourceURL: URL, outputURL: URL) throws {
        guard MDLAsset.canExportFileExtension("obj") else {
            throw ConversionError.formatNotSupported("obj")
        }

        let asset = MDLAsset(url: sourceURL)
        asset.loadTextures()

        guard asset.count > 0 else {
            throw ConversionError.loadFailed(sourceURL)
        }

        try asset.export(to: outputURL)
    }

    func convertToSTL(from sourceURL: URL, outputURL: URL) throws {
        guard MDLAsset.canExportFileExtension("stl") else {
            throw ConversionError.formatNotSupported("stl")
        }

        let asset = MDLAsset(url: sourceURL)

        guard asset.count > 0 else {
            throw ConversionError.loadFailed(sourceURL)
        }

        // STL only contains geometry, no textures
        try asset.export(to: outputURL)
    }

    func generateAllFormats(
        from usdzURL: URL,
        outputDirectory: URL
    ) async throws -> (objURL: URL, stlURL: URL) {
        let objURL = outputDirectory.appending(
            path: ExportFormat.obj.fileName()
        )
        let stlURL = outputDirectory.appending(
            path: ExportFormat.stl.fileName()
        )

        try convertToOBJ(from: usdzURL, outputURL: objURL)
        try convertToSTL(from: usdzURL, outputURL: stlURL)

        return (objURL, stlURL)
    }

    func canExport(_ format: ExportFormat) -> Bool {
        MDLAsset.canExportFileExtension(format.fileExtension)
    }
}
