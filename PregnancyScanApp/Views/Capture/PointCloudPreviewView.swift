import SwiftUI
import RealityKit

#if !targetEnvironment(simulator)
struct PointCloudPreviewView: View {

    let session: ObjectCaptureSession

    var body: some View {
        ZStack {
            ObjectCapturePointCloudView(session: session)
                .ignoresSafeArea()

            VStack {
                Spacer()

                Text("Point Cloud Preview")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 120)
            }
        }
    }
}
#endif
