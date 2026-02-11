import Foundation

final class FileManagerService {

    struct ScanFolderPaths {
        let root: URL
        let images: URL
        let snapshots: URL
        let models: URL
        let exports: URL
    }

    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var scansRootDirectory: URL {
        documentsDirectory.appending(path: AppConstants.scansRootDirectoryName)
    }

    func createScanFolder(named name: String? = nil) throws -> ScanFolderPaths {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate]
        let timestamp = formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")

        let folderName = name ?? "Scan_\(timestamp)"
        let scanFolder = scansRootDirectory.appending(path: folderName)

        let paths = ScanFolderPaths(
            root: scanFolder,
            images: scanFolder.appending(path: AppConstants.imagesDirectoryName),
            snapshots: scanFolder.appending(path: AppConstants.snapshotsDirectoryName),
            models: scanFolder.appending(path: AppConstants.modelsDirectoryName),
            exports: scanFolder.appending(path: AppConstants.exportsDirectoryName)
        )

        try fileManager.createDirectory(at: paths.images, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: paths.snapshots, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: paths.models, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: paths.exports, withIntermediateDirectories: true)

        return paths
    }

    func relativePath(for url: URL) -> String {
        let docsPath = documentsDirectory.path(percentEncoded: false)
        let fullPath = url.path(percentEncoded: false)
        if fullPath.hasPrefix(docsPath) {
            return String(fullPath.dropFirst(docsPath.count))
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        return fullPath
    }

    func deleteScanFolder(at url: URL) throws {
        if fileManager.fileExists(atPath: url.path(percentEncoded: false)) {
            try fileManager.removeItem(at: url)
        }
    }

    func scanFolderSize(at url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }
        return totalSize
    }

    func imageCount(in imagesURL: URL) -> Int {
        let contents = (try? fileManager.contentsOfDirectory(
            at: imagesURL,
            includingPropertiesForKeys: nil
        )) ?? []
        return contents.filter { url in
            let ext = url.pathExtension.lowercased()
            return ext == "heic" || ext == "jpg" || ext == "jpeg" || ext == "png"
        }.count
    }

    func formattedSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
