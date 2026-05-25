import SwiftUI

struct AppNavigationView: View {

    @Environment(AuthViewModel.self) private var authVM
    @State private var selectedTab: Tab = .meet

    var body: some View {
        // TODO [PP-002]: Replace `true` with `authVM.currentUser != nil` when auth is wired
        if true {
            switch selectedTab {
            case .profile:
                ProfileView(user: .mock, isOwner: true, selectedTab: $selectedTab)
            case .chat:
                ChatView(selectedTab: $selectedTab)
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
