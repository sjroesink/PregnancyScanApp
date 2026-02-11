import SwiftUI
import SwiftData

struct ScanHistoryListView: View {

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()

    var body: some View {
        List {
            if viewModel.scanRecords.isEmpty {
                ContentUnavailableView(
                    "No Scans",
                    systemImage: "cube.transparent",
                    description: Text("Completed scans will appear here.")
                )
            } else {
                ForEach(viewModel.scanRecords) { record in
                    ScanHistoryRow(record: record, viewModel: viewModel)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            navigateToRecord(record)
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
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Scan History")
        .onAppear {
            viewModel.fetchScans(context: modelContext)
        }
        .refreshable {
            viewModel.fetchScans(context: modelContext)
        }
    }

    private func navigateToRecord(_ record: ScanRecord) {
        switch record.status {
        case .completed:
            appState.navigateTo(.viewing(scanRecordID: record.id))
        case .reconstructing:
            appState.navigateTo(.reconstruction(scanRecordID: record.id))
        default:
            break
        }
    }
}

private struct ScanHistoryRow: View {
    let record: ScanRecord
    let viewModel: HomeViewModel

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView

            VStack(alignment: .leading, spacing: 4) {
                Text(record.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    statusBadge
                    Text("\(record.imageCount) images")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Text(record.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(viewModel.formattedSize(for: record))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
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
        .frame(width: 60, height: 60)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: record.status.iconName)
            Text(record.status.displayName)
        }
        .font(.caption2.bold())
        .foregroundStyle(statusColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.12))
        .clipShape(Capsule())
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
