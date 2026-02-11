import SwiftUI

@available(iOS 17.0, *)
struct DeviceCheckView: View {

    let result: DeviceCapabilityChecker.CapabilityResult

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            Text("Device Not Supported")
                .font(.title2.bold())

            Text("This app requires specific hardware capabilities to create 3D scans.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 12) {
                capabilityRow(
                    name: "LiDAR Scanner",
                    supported: result.hasLiDAR,
                    detail: "iPhone 12 Pro or later"
                )
                capabilityRow(
                    name: "Object Capture",
                    supported: result.supportsObjectCapture,
                    detail: "iOS 17+ on supported device"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)

            if !result.missingCapabilities.isEmpty {
                Text("Missing: \(result.missingCapabilities.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
    }

    private func capabilityRow(name: String, supported: Bool, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(supported ? .green : .red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
