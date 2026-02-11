import SwiftUI

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: String?

    var isPresented: Binding<Bool> {
        Binding(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )
    }

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: isPresented) {
                Button("OK") { error = nil }
            } message: {
                if let error {
                    Text(error)
                }
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<String?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}
