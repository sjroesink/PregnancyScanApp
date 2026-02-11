import SwiftUI
import SwiftData

@Observable
@MainActor
final class ExportViewModel {

    let conversionService = ModelConversionService()
    let exportService = ScanDataExportService()
    let fileManagerService = FileManagerService()

    private(set) var scanRecord: ScanRecord?
    private(set) var isConverting = false
    private(set) var availableFormats: Set<ExportFormat> = []
    private(set) var conversionError: String?
    private(set) var isPreparingMacExport = false
    private(set) var macExportURL: URL?

    var showShareSheet = false
    var shareItems: [Any] = []

    func loadRecord(id: UUID, context: ModelContext) {
        let descriptor = FetchDescriptor<ScanRecord>(
            predicate: #Predicate<ScanRecord> { $0.id == id }
        )
        scanRecord = try? context.fetch(descriptor).first

        // Check which formats are already available
        if let record = scanRecord {
            if record.usdzURL != nil { availableFormats.insert(.usdz) }
            if record.objURL != nil { availableFormats.insert(.obj) }
            if record.stlURL != nil { availableFormats.insert(.stl) }
        }
    }

    func generateAllFormats(context: ModelContext) async {
        guard let record = scanRecord,
              let usdzURL = record.usdzURL else {
            conversionError = "USDZ model not found."
            return
        }

        isConverting = true
        conversionError = nil

        do {
            let (objURL, stlURL) = try await conversionService.generateAllFormats(
                from: usdzURL,
                outputDirectory: record.modelsDirectoryURL
            )

            record.modelOBJPath = fileManagerService.relativePath(for: objURL)
            record.modelSTLPath = fileManagerService.relativePath(for: stlURL)
            try? context.save()

            availableFormats = [.usdz, .obj, .stl]
        } catch {
            conversionError = error.localizedDescription
            // USDZ is always available even if conversion fails
            availableFormats.insert(.usdz)
        }

        isConverting = false
    }

    func shareFormat(_ format: ExportFormat) {
        guard let record = scanRecord else { return }
        do {
            shareItems = try exportService.activityItems(for: format, scanRecord: record)
            showShareSheet = true
        } catch {
            conversionError = error.localizedDescription
        }
    }

    func prepareMacExport() async {
        guard let record = scanRecord else { return }

        isPreparingMacExport = true
        do {
            let exportURL = try exportService.packageImagesForMacExport(
                imagesDirectory: record.imagesDirectoryURL,
                exportsDirectory: record.exportsDirectoryURL,
                scanName: record.name.replacingOccurrences(of: " ", with: "_")
            )
            macExportURL = exportURL
            shareItems = exportService.macExportActivityItems(exportFolderURL: exportURL)
            showShareSheet = true
        } catch {
            conversionError = error.localizedDescription
        }
        isPreparingMacExport = false
    }

    var modelSizeText: String? {
        guard let record = scanRecord else { return nil }
        let size = fileManagerService.scanFolderSize(at: record.modelsDirectoryURL)
        return fileManagerService.formattedSize(size)
    }
}
