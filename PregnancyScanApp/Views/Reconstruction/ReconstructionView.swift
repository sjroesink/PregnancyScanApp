import SwiftUI
import SwiftData

struct ReconstructionView: View {

    let scanRecordID: UUID

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ReconstructionViewModel()
    @State private var showCancelConfirmation = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            progressSection

            stageSection

            if let timeRemaining = viewModel.formattedTimeRemaining {
                Text(timeRemaining)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.isComplete {
                viewModelButton
            } else if viewModel.isProcessing {
                cancelButton
            }

            if let error = viewModel.error {
                errorSection(error)
            }
        }
        .padding(24)
        .navigationTitle("Reconstruction")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isProcessing)
        .confirmationDialog(
            "Cancel Reconstruction?",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel Reconstruction", role: .destructive) {
                viewModel.cancelReconstruction()
            }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("The 3D model generation will be stopped.")
        }
        .task {
            viewModel.loadRecord(id: scanRecordID, context: modelContext)
            await viewModel.startReconstruction(context: modelContext)
        }
    }

    // MARK: - Subviews

    private var progressSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: Double(viewModel.progress))
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.progress)

                VStack(spacing: 4) {
                    Text("\(viewModel.progressPercentage)%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())

                    Image(systemName: "cube.transparent")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 160, height: 160)
        }
    }

    private var stageSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.isComplete ? "Model Ready" : "Building 3D Model")
                .font(.title2.bold())

            Text(viewModel.currentStage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !viewModel.isComplete && !viewModel.isProcessing && viewModel.error == nil {
                ProgressView()
                    .padding(.top, 8)
            }
        }
    }

    private var viewModelButton: some View {
        Button {
            appState.navigateTo(.viewing(scanRecordID: scanRecordID))
        } label: {
            Label("View 3D Model", systemImage: "cube.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var cancelButton: some View {
        Button("Cancel", role: .destructive) {
            showCancelConfirmation = true
        }
        .buttonStyle(.bordered)
    }

    private func errorSection(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.red)

            Text("Reconstruction Failed")
                .font(.headline)

            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Go Back") {
                appState.popToRoot()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
