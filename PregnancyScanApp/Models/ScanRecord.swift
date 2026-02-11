import Foundation
import SwiftData

@Model
final class ScanRecord {
    var id: UUID
    var name: String
    var createdAt: Date
    var scanFolderPath: String
    var thumbnailPath: String?
    var modelUSDZPath: String?
    var modelOBJPath: String?
    var modelSTLPath: String?
    var imageCount: Int
    var statusRawValue: String
    var notes: String?

    init(
        name: String,
        scanFolderPath: String,
        imageCount: Int = 0,
        status: ScanStatus = .preparing
    ) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.scanFolderPath = scanFolderPath
        self.imageCount = imageCount
        self.statusRawValue = status.rawValue
    }

    var status: ScanStatus {
        get { ScanStatus(rawValue: statusRawValue) ?? .failed }
        set { statusRawValue = newValue.rawValue }
    }

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var scanFolderURL: URL {
        documentsDirectory.appending(path: scanFolderPath)
    }

    var imagesDirectoryURL: URL {
        scanFolderURL.appending(path: AppConstants.imagesDirectoryName)
    }

    var snapshotsDirectoryURL: URL {
        scanFolderURL.appending(path: AppConstants.snapshotsDirectoryName)
    }

    var modelsDirectoryURL: URL {
        scanFolderURL.appending(path: AppConstants.modelsDirectoryName)
    }

    var exportsDirectoryURL: URL {
        scanFolderURL.appending(path: AppConstants.exportsDirectoryName)
    }

    var usdzURL: URL? {
        guard let path = modelUSDZPath else { return nil }
        return documentsDirectory.appending(path: path)
    }

    var objURL: URL? {
        guard let path = modelOBJPath else { return nil }
        return documentsDirectory.appending(path: path)
    }

    var stlURL: URL? {
        guard let path = modelSTLPath else { return nil }
        return documentsDirectory.appending(path: path)
    }

    var thumbnailURL: URL? {
        guard let path = thumbnailPath else { return nil }
        return documentsDirectory.appending(path: path)
    }

    func modelURL(for format: ExportFormat) -> URL? {
        switch format {
        case .usdz: return usdzURL
        case .obj: return objURL
        case .stl: return stlURL
        }
    }
}
