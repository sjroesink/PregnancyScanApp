import SwiftUI

struct CaptureGuidanceView: View {

    let guidanceText: String
    let currentHeight: CaptureSessionService.ScanHeight
    let subjectGuidance: String

    var body: some View {
        VStack(spacing: 12) {
            // Subject-facing guidance (large, prominent)
            Text(subjectGuidance)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            // Camera operator guidance
            HStack(spacing: 8) {
                heightIcon
                    .font(.body)
                    .foregroundStyle(.yellow)

                Text(guidanceText)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private var heightIcon: some View {
        Group {
            switch currentHeight {
            case .low:
                Image(systemName: "arrow.down.circle.fill")
            case .mid:
                Image(systemName: "arrow.right.circle.fill")
            case .high:
                Image(systemName: "arrow.up.circle.fill")
            }
        }
    }
}
