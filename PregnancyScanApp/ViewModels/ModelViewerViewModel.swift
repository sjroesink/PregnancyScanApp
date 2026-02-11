import SwiftUI
import SwiftData
import QuickLook

@Observable
@MainActor
final class ModelViewerViewModel {

    private(set) var scanRecord: ScanRecord?
    private(set) var modelURL: URL?
    private(set) var isLoading = true
    private(set) var error: String?
    var showQuickLook = false

    func loadRecord(id: UUID, context: ModelContext) {
        let descriptor = FetchDescriptor<ScanRecord>(
            predicate: #Predicate<ScanRecord> { $0.id == id }
        )
        scanRecord = try? context.fetch(descriptor).first

        if let usdzURL = scanRecord?.usdzURL,
           FileManager.default.fileExists(atPath: usdzURL.path(percentEncoded: false)) {
            modelURL = usdzURL
        } else {
            error = "3D model file not found."
        }

        isLoading = false
    }

    var modelName: String {
        scanRecord?.name ?? "3D Model"
    }

    var imageCount: Int {
        scanRecord?.imageCount ?? 0
    }

    var scanDate: Date? {
        scanRecord?.createdAt
    }

    var hasModel: Bool {
        modelURL != nil
    }
}
