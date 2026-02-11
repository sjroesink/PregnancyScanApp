import SwiftUI

struct MacExportGuideView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    stepsSection

                    tipsSection
                }
                .padding()
            }
            .navigationTitle("Mac Reconstruction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 40))
                .foregroundStyle(.blue)

            Text("Higher Quality Reconstruction")
                .font(.title2.bold())

            Text("Use your Mac's processing power to create a higher quality 3D model from the captured images.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Steps")
                .font(.headline)

            stepRow(number: 1, text: "Transfer the exported images folder to your Mac via AirDrop, iCloud Drive, or USB cable.")
            stepRow(number: 2, text: "Open Reality Composer Pro on your Mac (requires macOS Sonoma or later).")
            stepRow(number: 3, text: "Go to File > New Project from Object Capture Images.")
            stepRow(number: 4, text: "Select the folder containing the exported images.")
            stepRow(number: 5, text: "Choose the detail level: 'Full' or 'Raw' for highest quality.")
            stepRow(number: 6, text: "Click 'Reconstruct' and wait for processing to complete.")
            stepRow(number: 7, text: "Export the resulting model in your preferred format (USDZ, OBJ, or STL).")
        }
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tips")
                .font(.headline)

            Text("The Mac reconstruction produces significantly higher quality models with better geometry and texture detail. It can also generate quad meshes suitable for animation workflows.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("The overcapture images included in the export provide additional angles that weren't used for the on-device reconstruction, resulting in a more complete model.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
}
