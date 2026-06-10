import SwiftUI

struct ProfileAlertsModifier: ViewModifier {
    @Binding var showDeleteConfirm: Bool
    @Binding var showLogoutConfirm: Bool
    let onDelete: () -> Void
    let onLogout: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(
                "profile.deleteAccount.title",
                isPresented: $showDeleteConfirm
            ) {
                Button("profile.deleteAccount.confirm", role: .destructive, action: onDelete)
                Button("sheet.cancel", role: .cancel) {}
            } message: {
                Text("profile.deleteAccount.message")
            }
            .alert(
                "profile.logout.title",
                isPresented: $showLogoutConfirm
            ) {
                Button("profile.logout.confirm", role: .destructive, action: onLogout)
                Button("sheet.cancel", role: .cancel) {}
            } message: {
                Text("profile.logout.message")
            }
    }
}

extension View {
    func profileAlerts(
        showDeleteConfirm: Binding<Bool>,
        showLogoutConfirm: Binding<Bool>,
        onDelete: @escaping () -> Void,
        onLogout: @escaping () -> Void
    ) -> some View {
        modifier(
            ProfileAlertsModifier(
                showDeleteConfirm: showDeleteConfirm,
                showLogoutConfirm: showLogoutConfirm,
                onDelete: onDelete,
                onLogout: onLogout
            )
        )
    }
}
