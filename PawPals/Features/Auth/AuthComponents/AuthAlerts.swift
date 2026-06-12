import SwiftUI

struct AuthAlertsModifier: ViewModifier {
    let errorMessage: String?
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(
                String(localized: "common.error"),
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { onDismiss() } }
                )
            ) {
                Button(String(localized: "common.ok"), action: onDismiss)
            } message: {
                Text(errorMessage ?? "")
            }
    }
}

extension View {
    func authAlerts(
        errorMessage: String?,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(AuthAlertsModifier(errorMessage: errorMessage, onDismiss: onDismiss))
    }
}
