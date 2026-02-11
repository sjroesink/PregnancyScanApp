import UIKit
import Foundation

final class ScanDataExportService {

    enum ExportError: LocalizedError {
        case noImagesFound
        case zipFailed
        case modelNotFound(ExportFormat)

        var errorDescription: String? {
            switch self {
            case .noImagesFound:
                return "No captured images found to export."
            case .zipFailed:
                return "Failed to create export package."
            case .modelNotFound(let format):
                return "\(format.displayName) model file not found."
            }
        }
    }

    /// Package raw images as a folder for Mac-based reconstruction.
    /// Returns the URL of the packaged directory (ready to share via AirDrop/Files).
    func packageImagesForMacExport(
        imagesDirectory: URL,
        exportsDirectory: URL,
        scanName: String
    ) throws -> URL {
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil)
        let images = contents.filter { url in
            let ext = url.pathExtension.lowercased()
            return ext == "heic" || ext == "jpg" || ext == "jpeg" || ext == "png"
        }

        guard !images.isEmpty else {
            throw ExportError.noImagesFound
        }

        // Create a named export folder containing the images
        let exportFolderName = "\(scanName)_MacExport"
        let exportFolder = exportsDirectory.appending(path: exportFolderName)

        if fm.fileExists(atPath: exportFolder.path(percentEncoded: false)) {
            try fm.removeItem(at: exportFolder)
        }
        try fm.createDirectory(at: exportFolder, withIntermediateDirectories: true)

        // Copy images to export folder
        for imageURL in images {
            let destination = exportFolder.appending(path: imageURL.lastPathComponent)
            try fm.copyItem(at: imageURL, to: destination)
        }

        return exportFolder
    }

    /// Create activity items for sharing a specific format
    func activityItems(for format: ExportFormat, scanRecord: ScanRecord) throws -> [Any] {
        guard let url = scanRecord.modelURL(for: format),
              FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            throw ExportError.modelNotFound(format)
        }
        return [url]
    }

    /// Create activity items for sharing the Mac export folder
    func macExportActivityItems(exportFolderURL: URL) -> [Any] {
        [exportFolderURL]
    }
}
