import SwiftUI
import SwiftData

struct HomeView: View {

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var capabilityResult = DeviceCapabilityChecker.checkCapabilities()

    var body: some View {
        Group {
            if capabilityResult.isSupported {
                scanContentView
            } else {
                DeviceCheckView(result: capabilityResult)
            }
        }
        .navigationTitle("BumpScan 3D")
        .onAppear {
            viewModel.fetchScans(context: modelContext)
        }
    }

    private var scanContentView: some View {
        VStack(spacing: 0) {
            if viewModel.scanRecords.isEmpty {
                emptyStateView
            } else {
                scanListView
            }

            Spacer()

            newScanButton
                .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "figure.stand")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Scans Yet")
                .font(.title2.bold())

            Text("Create your first 3D scan of a pregnancy bump.\nThe model can be exported for 3D printing.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var scanListView: some View {
        List {
            Section {
                ForEach(viewModel.scanRecords) { record in
                    ScanRecordRow(record: record, viewModel: viewModel)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            navigateToScan(record)
                        }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteScan(
                            viewModel.scanRecords[index],
                            context: modelContext
                        )
                    }
                }
            } header: {
                Text("Previous Scans")
            }
        }
        .listStyle(.insetGrouped)
    }

    private var newScanButton: some View {
        Button {
            startNewScan()
        } label: {
            Label("New Scan", systemImage: "plus.viewfinder")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(viewModel.isCreatingScan)
    }

    private func startNewScan() {
        appState.navigateTo(.preparation)
    }

    private func navigateToScan(_ record: ScanRecord) {
        switch record.status {
        case .preparing, .capturing:
            appState.navigateTo(.capturing(scanRecordID: record.id))
        case .reconstructing:
            appState.navigateTo(.reconstruction(scanRecordID: record.id))
        case .completed:
            appState.navigateTo(.viewing(scanRecordID: record.id))
        case .failed:
            appState.navigateTo(.viewing(scanRecordID: record.id))
        }
    }
}

private struct ScanRecordRow: View {
    let record: ScanRecord
    let viewModel: HomeViewModel

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView

            VStack(alignment: .leading, spacing: 4) {
                Text(record.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label(record.status.displayName, systemImage: record.status.iconName)
                        .font(.caption)
                        .foregroundStyle(statusColor)

                    Text("\(record.imageCount) images")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(record.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var thumbnailView: some View {
        Group {
            if let thumbnailURL = record.thumbnailURL,
               let uiImage = UIImage(contentsOfFile: thumbnailURL.path(percentEncoded: false)) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "cube")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 56, height: 56)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var statusColor: Color {
        switch record.status {
        case .preparing: return .orange
        case .capturing: return .blue
        case .reconstructing: return .purple
        case .completed: return .green
        case .failed: return .red
        }
    }
}
