import SwiftUI
import SwiftData

struct ExportOptionsView: View {

    let scanRecordID: UUID

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ExportViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                formatSection

                printingWarningsSection

                macExportSection

                if let error = viewModel.conversionError {
                    errorBanner(error)
                }
            }
            .padding()
        }
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $viewModel.showShareSheet) {
            ActivityView(activityItems: viewModel.shareItems)
        }
        .task {
            viewModel.loadRecord(id: scanRecordID, context: modelContext)
            await viewModel.generateAllFormats(context: modelContext)
        }
    }

    // MARK: - Sections

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Export Formats", systemImage: "square.and.arrow.up")
                .font(.headline)

            if viewModel.isConverting {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Converting formats...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            ForEach(ExportFormat.allCases) { format in
                formatRow(format)
            }

            if let sizeText = viewModel.modelSizeText {
                Text("Total model size: \(sizeText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatRow(_ format: ExportFormat) -> some View {
        let isAvailable = viewModel.availableFormats.contains(format)

        return HStack(spacing: 12) {
            Image(systemName: format.iconName)
                .font(.title3)
                .foregroundStyle(isAvailable ? .blue : .gray)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(format.displayName)
                    .font(.subheadline.bold())
                Text(format.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isAvailable {
                Button {
                    viewModel.shareFormat(format)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var printingWarningsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("3D Printing Notes", systemImage: "printer.fill")
                .font(.headline)

            warningCard(
                icon: "cube.transparent",
                title: "Mesh May Need Repair",
                description: "The back of the model may have holes since only the front hemisphere was scanned. Use mesh repair tools (e.g., Meshmixer) before printing."
            )

            warningCard(
                icon: "ruler",
                title: "Scale Adjustment Needed",
                description: "The model uses meters as the unit. Most slicers expect millimeters. Scale the model by 1000x in your slicer software (PrusaSlicer, Cura, etc.)."
            )

            warningCard(
                icon: "paintbrush",
                title: "STL Has No Color",
                description: "STL files contain only geometry without textures or color. Use USDZ or OBJ if you need textured output."
            )
        }
    }

    private func warningCard(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemOrange).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var macExportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Higher Quality Export", systemImage: "desktopcomputer")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Export raw images to your Mac for higher quality reconstruction using Reality Composer Pro.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    Task { await viewModel.prepareMacExport() }
                } label: {
                    if viewModel.isPreparingMacExport {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Export Images for Mac", systemImage: "arrow.up.doc")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isPreparingMacExport)

                Button {
                    appState.navigateTo(.export(scanRecordID: scanRecordID))
                } label: {
                    Text("Mac Reconstruction Guide")
                        .font(.caption)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func errorBanner(_ error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemRed).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - UIActivityViewController Wrapper

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
