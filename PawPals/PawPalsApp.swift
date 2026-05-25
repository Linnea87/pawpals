import SwiftUI
import FirebaseCore

@main
struct PawPalsApp: App {
    @State private var authViewModel: AuthViewModel
    @State private var meetViewModel: MeetViewModel
    @State private var chatViewModel: ChatViewModel

    init() {
        FirebaseApp.configure()
        _authViewModel = State(initialValue: AuthViewModel(repository: AuthService()))
        _meetViewModel = State(initialValue: MeetViewModel())
        _chatViewModel = State(initialValue: ChatViewModel(repository: ChatService()))
    }

    var body: some Scene {
        WindowGroup {
            AppNavigationView()
                .environment(authViewModel)
                .environment(meetViewModel)
                .environment(chatViewModel)
        }
    }
}
