import SwiftUI

@Observable
@MainActor
final class AppState {

    enum Screen: Hashable {
        case home
        case preparation
        case capturing(scanRecordID: UUID)
        case reconstruction(scanRecordID: UUID)
        case viewing(scanRecordID: UUID)
        case export(scanRecordID: UUID)
    }

    var navigationPath = NavigationPath()
    var showError = false
    var errorMessage: String?

    func navigateTo(_ screen: Screen) {
        navigationPath.append(screen)
    }

    func popToRoot() {
        navigationPath = NavigationPath()
    }

    func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
