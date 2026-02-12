import SwiftUI
import RealityKit
import SwiftData

struct CaptureContainerView: View {

    let scanRecordID: UUID

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ScanSessionViewModel()
    @State private var showCancelConfirmation = false

    var body: some View {
        ZStack {
            if let session = viewModel.session {
                captureSessionView(session: session)
            } else {
                startingView
            }

            if viewModel.isCountingDown {
                countdownOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    showCancelConfirmation = true
                }
                .foregroundStyle(.white)
            }
            ToolbarItem(placement: .principal) {
                Text(viewModel.passProgressText)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .confirmationDialog(
            "Cancel Scan?",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel Scan", role: .destructive) {
                viewModel.cancelScan()
                appState.popToRoot()
            }
            Button("Continue Scanning", role: .cancel) {}
        } message: {
            Text("All captured images will be discarded.")
        }
        .sheet(isPresented: $viewModel.showPassCompleteSheet) {
            passCompleteSheet
        }
        .task {
            await startSession()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func captureSessionView(session: RealityKit.ObjectCaptureSession) -> some View {
        ZStack {
            RealityKit.ObjectCaptureView(session: session)

            if viewModel.showPointCloudPreview {
                RealityKit.ObjectCapturePointCloudView(session: session)
                    .transition(.opacity)
            }

            VStack {
                Spacer()

                CaptureGuidanceView(
                    guidanceText: viewModel.guidanceText,
                    currentHeight: viewModel.currentHeight,
                    subjectGuidance: AppConstants.SubjectGuidance.holdStill
                )

                CaptureOverlayView(
                    imageCount: viewModel.imageCount,
                    canFinish: viewModel.canFinish,
                    isLastPass: viewModel.isLastPass,
                    showPointCloud: viewModel.showPointCloudPreview,
                    onTogglePointCloud: { viewModel.togglePointCloudPreview() },
                    onCompletePass: { viewModel.completeCurrentPass() },
                    onFinish: { viewModel.finishCapture() }
                )
            }

            ScanPassIndicatorView(
                currentHeight: viewModel.currentHeight,
                completedPasses: viewModel.completedPasses
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 60)
            .padding(.trailing, 16)
        }
        .ignoresSafeArea()
    }

    private var startingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Preparing scan...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(AppConstants.SubjectGuidance.holdStill)
                    .font(.title3)
                    .foregroundStyle(.white)

                Text("\(viewModel.countdownValue)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }

    private var passCompleteSheet: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("\(viewModel.currentHeight.title) Pass Complete")
                .font(.title2.bold())

            Text("You captured \(viewModel.imageCount) images so far.\nReady for the next pass?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let nextHeight = CaptureSessionService.ScanHeight(
                rawValue: viewModel.currentHeight.rawValue + 1
            ) {
                Text("Next: \(nextHeight.guidance)")
                    .font(.callout)
                    .foregroundStyle(.blue)
            }

            HStack(spacing: 16) {
                Button("Finish Now") {
                    viewModel.finishCapture()
                    navigateToReconstruction()
                }
                .buttonStyle(.bordered)

                Button("Next Pass") {
                    viewModel.advanceToNextPass()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func startSession() async {
        do {
            try await viewModel.startNewScan(context: modelContext)
        } catch {
            appState.showError("Failed to start scan: \(error.localizedDescription)")
            appState.popToRoot()
        }
    }

    private func navigateToReconstruction() {
        guard let record = viewModel.scanRecord else { return }
        viewModel.updateRecordForReconstruction()
        try? modelContext.save()
        appState.navigateTo(.reconstruction(scanRecordID: record.id))
    }
}
