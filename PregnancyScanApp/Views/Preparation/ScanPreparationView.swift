import SwiftUI

struct ScanPreparationView: View {

    @Environment(AppState.self) private var appState
    @State private var readyToScan = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection

                tipsSection

                subjectTipsSection

                environmentTipsSection

                startButton
            }
            .padding()
        }
        .navigationTitle("Scan Preparation")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.stand")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Prepare for Scanning")
                .font(.title2.bold())

            Text("Follow these tips for the best 3D model quality.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Camera Operator", icon: "camera.fill")

            PreparationTipCard(
                icon: "move.3d",
                title: "Semicircular Movement",
                description: "Walk in a semicircle around the subject. The app will guide you through three passes at different heights."
            )

            PreparationTipCard(
                icon: "tortoise.fill",
                title: "Move Slowly",
                description: "Move slowly and steadily. Quick movements cause blurry captures that reduce model quality."
            )

            PreparationTipCard(
                icon: "arrow.triangle.2.circlepath",
                title: "Overlap Coverage",
                description: "Keep each frame overlapping with the previous one. This helps the 3D reconstruction algorithm."
            )
        }
    }

    private var subjectTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "For the Subject", icon: "figure.stand")

            PreparationTipCard(
                icon: "tshirt.fill",
                title: "Clothing",
                description: "Wear a fitted top with some texture or pattern. Avoid pure white, black, or shiny fabrics. Patterned clothing helps the scan significantly."
            )

            PreparationTipCard(
                icon: "hand.raised.fill",
                title: "Posture",
                description: "Stand still with arms slightly away from the body. Lean against a wall for stability. Breathe normally."
            )

            PreparationTipCard(
                icon: "circle.dotted",
                title: "Bare Skin Tip",
                description: "If scanning bare skin, consider placing temporary body-safe stickers or markers at key points. This dramatically improves scan quality on low-texture surfaces."
            )
        }
    }

    private var environmentTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Environment", icon: "light.max")

            PreparationTipCard(
                icon: "sun.max.fill",
                title: "Lighting",
                description: "Use soft, even lighting from multiple directions. Avoid direct sunlight or single-point lights that create harsh shadows."
            )

            PreparationTipCard(
                icon: "rectangle.dashed",
                title: "Background",
                description: "A plain, non-reflective background helps the scan focus on the subject. Avoid cluttered backgrounds."
            )
        }
    }

    private var startButton: some View {
        Button {
            appState.navigateTo(.capturing(scanRecordID: UUID()))
        } label: {
            Label("Start Scanning", systemImage: "viewfinder")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.top, 8)
    }
}

// MARK: - Supporting Views

private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .padding(.top, 4)
    }
}
