import SwiftUI
import SwiftData
import QuickLook

struct ModelViewerView: View {

    let scanRecordID: UUID

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ModelViewerViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading model...")
            } else if let modelURL = viewModel.modelURL {
                modelContentView(url: modelURL)
            } else {
                errorView
            }
        }
        .navigationTitle(viewModel.modelName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.hasModel {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.showQuickLook = true
                        } label: {
                            Label("View in AR", systemImage: "arkit")
                        }

                        Button {
                            appState.navigateTo(.export(scanRecordID: scanRecordID))
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .quickLookPreview($viewModel.showQuickLook, items: viewModel.modelURL.map { [$0] } ?? [])
        .onAppear {
            viewModel.loadRecord(id: scanRecordID, context: modelContext)
        }
    }

    // MARK: - Subviews

    private func modelContentView(url: URL) -> some View {
        VStack(spacing: 0) {
            ModelSceneView(modelURL: url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            modelInfoBar
        }
    }

    private var modelInfoBar: some View {
        HStack(spacing: 16) {
            if viewModel.imageCount > 0 {
                Label("\(viewModel.imageCount) photos", systemImage: "photo.stack")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let date = viewModel.scanDate {
                Label(date, format: .dateTime.month().day().year(), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                viewModel.showQuickLook = true
            } label: {
                Label("View in AR", systemImage: "arkit")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                appState.navigateTo(.export(scanRecordID: scanRecordID))
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(.caption.bold())
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Model Not Available")
                .font(.title3.bold())

            if let error = viewModel.error {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Go Back") {
                appState.popToRoot()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - QuickLook Helper

private extension View {
    func quickLookPreview(_ isPresented: Binding<Bool>, items: [URL]) -> some View {
        self.sheet(isPresented: isPresented) {
            if let url = items.first {
                QuickLookPreviewView(url: url)
            }
        }
    }
}

private struct QuickLookPreviewView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as QLPreviewItem
        }
    }
}
