import SwiftUI

struct CaptureOverlayView: View {

    let imageCount: Int
    let canFinish: Bool
    let isLastPass: Bool
    let showPointCloud: Bool
    let onTogglePointCloud: () -> Void
    let onCompletePass: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            imageCountBadge

            HStack(spacing: 20) {
                pointCloudButton

                Spacer()

                if isLastPass || canFinish {
                    finishButton
                } else {
                    nextPassButton
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    private var imageCountBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "camera.fill")
                .font(.caption)
            Text("\(imageCount) photos")
                .font(.subheadline.monospacedDigit())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var pointCloudButton: some View {
        Button {
            onTogglePointCloud()
        } label: {
            Image(systemName: showPointCloud ? "eye.fill" : "eye.slash.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }

    private var nextPassButton: some View {
        Button {
            onCompletePass()
        } label: {
            Label("Next Pass", systemImage: "arrow.right.circle.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.blue)
                .clipShape(Capsule())
        }
    }

    private var finishButton: some View {
        Button {
            onFinish()
        } label: {
            Label("Finish", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.green)
                .clipShape(Capsule())
        }
    }
}
