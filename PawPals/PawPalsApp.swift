import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct PawPalsApp: App {
    @State private var authViewModel: AuthViewModel
    @State private var meetViewModel: MeetViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var notificationService: NotificationService
    @State private var locationViewModel: LocationViewModel
    @State private var profileViewModel: ProfileViewModel
    @State private var filterViewModel: FilterViewModel


    init() {
        FirebaseApp.configure()

        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        let locationViewModel = LocationViewModel()
        _locationViewModel = State(initialValue: locationViewModel)
        _meetViewModel = State(initialValue: MeetViewModel(locationViewModel: locationViewModel))
        _authViewModel = State(initialValue: AuthViewModel(repository: AuthService(), userRepository: UserService()))
        _chatViewModel = State(initialValue: ChatViewModel(chatRepository: ChatService(), userRepository: UserService()))
        _notificationService = State(initialValue: NotificationService(userRepository: UserService()))
        _profileViewModel = State(initialValue: ProfileViewModel(userRepository: UserService(), user: .mock))
        _filterViewModel = State(initialValue: FilterViewModel())
    }

    var body: some Scene {
        WindowGroup {
            AppNavigationView()
                .environment(authViewModel)
                .environment(meetViewModel)
                .environment(filterViewModel)
                .environment(chatViewModel)
                .environment(notificationService)
                .environment(locationViewModel)
                .environment(profileViewModel)
                .onChange(of: authViewModel.currentUser?.id) { _, _ in
                     if let user = authViewModel.currentUser {
                         profileViewModel.user = user
                         Task { await profileViewModel.loadUser(userId: user.id) }
                     } else {
                         profileViewModel.user = .mock
                     }
                 }

                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
