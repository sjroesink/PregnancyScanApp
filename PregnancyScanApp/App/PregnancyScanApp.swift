import SwiftUI
import SwiftData

@main
struct PregnancyScanApp: App {

    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $appState.navigationPath) {
                HomeView()
                    .navigationDestination(for: AppState.Screen.self) { screen in
                        switch screen {
                        case .home:
                            HomeView()
                        case .preparation:
                            ScanPreparationView()
                        case .capturing(let scanID):
                            #if ENABLE_OBJECT_CAPTURE
                            CaptureContainerView(scanRecordID: scanID)
                            #else
                            Text("Object Capture not available in this build")
                            #endif
                        case .reconstruction(let scanID):
                            #if ENABLE_OBJECT_CAPTURE
                            ReconstructionView(scanRecordID: scanID)
                            #else
                            Text("Reconstruction not available in this build")
                            #endif
                        case .viewing(let scanID):
                            ModelViewerView(scanRecordID: scanID)
                        case .export(let scanID):
                            ExportOptionsView(scanRecordID: scanID)
                        }
                    }
            }
            .environment(appState)
            .alert("Error", isPresented: $appState.showError) {
                Button("OK") { appState.errorMessage = nil }
            } message: {
                if let message = appState.errorMessage {
                    Text(message)
                }
            }
        }
        .modelContainer(for: ScanRecord.self)
    }
}
