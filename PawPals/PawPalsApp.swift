import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct PawPalsApp: App {
    @State private var authViewModel: AuthViewModel
    @State private var meetViewModel: MeetViewModel
    @State private var chatViewModel: ChatViewModel

    init() {
        FirebaseApp.configure()

        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }

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
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
