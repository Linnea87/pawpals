import SwiftUI

struct SideBarView: View {
    let onEditProfile: () -> Void
    let onLogout: () -> Void
    let onDeleteAccount: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            Text("profile.editProfile")
                .foregroundStyle(Theme.darkBrown)
                .contentShape(Rectangle())
                .onTapGesture(perform: onEditProfile)

            Divider()

            Spacer()

            Divider()

            Text("profile.logOut")
                .foregroundStyle(Theme.terracotta)
                .contentShape(Rectangle())
                .onTapGesture(perform: onLogout)

            Text("profile.deleteAccount")
                .font(.subheadline)
                .foregroundStyle(.red)
                .contentShape(Rectangle())
                .onTapGesture(perform: onDeleteAccount)

            Spacer()
        }
        .padding(.top, Spacing.sidebarTop)
        .padding(.horizontal, Spacing.large)
        .containerRelativeFrame(.horizontal, count: 3, span: 2, spacing: Spacing.none)
        .frame(maxHeight: .infinity)
        .background(Theme.offWhite)
        .ignoresSafeArea()
        .transition(.move(edge: .trailing))
    }
}
