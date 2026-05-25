import SwiftUI

struct AppNavigationView: View {

    @Environment(AuthViewModel.self) private var authVM
    @State private var selectedTab: Tab = .meet

    var body: some View {

        if authVM.isAuthenticated {
            switch selectedTab {
            case .profile:
                ProfileView(user: .mock, isOwner: true, selectedTab: $selectedTab)
            case .chat:
                ChatView(selectedTab: $selectedTab, currentUserID: authVM.currentUserId)
            case .meet:
                MeetView(selectedTab: $selectedTab)
            }
        } else {
            NavigationStack {
                AuthView()
            }
        }
    }
}
