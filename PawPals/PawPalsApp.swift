import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct PawPalsApp: App {
    @State private var authViewModel: AuthViewModel
    @State private var meetViewModel: MeetViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var notificationService: NotificationService
    @State private var locationService: LocationService
    @State private var profileViewModel: ProfileViewModel


    init() {
        FirebaseApp.configure()

        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        let locationService = LocationService()
        _locationService = State(initialValue: locationService)
        _meetViewModel = State(initialValue: MeetViewModel(locationService: locationService))
        _authViewModel = State(initialValue: AuthViewModel(repository: AuthService(), userRepository: UserService()))
        _chatViewModel = State(initialValue: ChatViewModel(chatRepository: ChatService(), userRepository: UserService()))
        _notificationService = State(initialValue: NotificationService(userRepository: UserService()))
        _profileViewModel = State(initialValue: ProfileViewModel(userRepository: UserService(), user: .mock))
    }

    var body: some Scene {
        WindowGroup {
            AppNavigationView()
                .environment(authViewModel)
                .environment(meetViewModel)
                .environment(chatViewModel)
                .environment(notificationService)
                .environment(locationService)
                .environment(profileViewModel)
                .onChange(of: authViewModel.currentUser?.id) { _, _ in
                    if let user = authViewModel.currentUser {
                        profileViewModel.user = user
                    }
                }

                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
