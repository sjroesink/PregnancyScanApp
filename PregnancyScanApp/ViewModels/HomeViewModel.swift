import SwiftUI
import SwiftData

@Observable
@MainActor
final class HomeViewModel {

    let fileManagerService = FileManagerService()

    var scanRecords: [ScanRecord] = []
    var isCreatingScan = false
    var showDeleteConfirmation = false
    var recordToDelete: ScanRecord?

    func fetchScans(context: ModelContext) {
        let descriptor = FetchDescriptor<ScanRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        scanRecords = (try? context.fetch(descriptor)) ?? []
    }

    func createNewScan(context: ModelContext) throws -> ScanRecord {
        isCreatingScan = true
        defer { isCreatingScan = false }

        let paths = try fileManagerService.createScanFolder()
        let relativePath = fileManagerService.relativePath(for: paths.root)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let name = "Scan \(formatter.string(from: Date()))"

        let record = ScanRecord(name: name, scanFolderPath: relativePath)
        context.insert(record)
        try context.save()

        return record
    }

    func deleteScan(_ record: ScanRecord, context: ModelContext) {
        do {
            try fileManagerService.deleteScanFolder(at: record.scanFolderURL)
            context.delete(record)
            try context.save()
            fetchScans(context: context)
        } catch {
            // Deletion failed silently; record remains
        }
    }

    func formattedSize(for record: ScanRecord) -> String {
        let size = fileManagerService.scanFolderSize(at: record.scanFolderURL)
        return fileManagerService.formattedSize(size)
    }
}
