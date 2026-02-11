#if ENABLE_OBJECT_CAPTURE
import SwiftUI

@available(iOS 17.0, *)
struct ScanPassIndicatorView: View {

    let currentHeight: CaptureSessionService.ScanHeight
    let completedPasses: Set<CaptureSessionService.ScanHeight>

    var body: some View {
        VStack(spacing: 6) {
            ForEach(CaptureSessionService.ScanHeight.allCases) { height in
                passIndicator(for: height)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func passIndicator(for height: CaptureSessionService.ScanHeight) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(indicatorColor(for: height))
                .frame(width: 10, height: 10)

            Text(height.title)
                .font(.caption2)
                .foregroundStyle(.white)
        }
    }

    private func indicatorColor(for height: CaptureSessionService.ScanHeight) -> Color {
        if completedPasses.contains(height) {
            return .green
        } else if height == currentHeight {
            return .blue
        } else {
            return .gray.opacity(0.5)
        }
    }
}
#endif
