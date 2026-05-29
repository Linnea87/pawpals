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

    init() {
        FirebaseApp.configure()

        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        let locationService = LocationService()
        _locationService = State(initialValue: locationService)
        _meetViewModel = State(initialValue: MeetViewModel(locationService: locationService))
        _authViewModel = State(initialValue: AuthViewModel(repository: AuthService()))
        _chatViewModel = State(initialValue: ChatViewModel(repository: ChatService()))
        _notificationService = State(initialValue: NotificationService(userRepository: UserService())) 
    }

    var body: some Scene {
        WindowGroup {
            AppNavigationView()
                .environment(authViewModel)
                .environment(meetViewModel)
                .environment(chatViewModel)
                .environment(notificationService)
                .environment(locationService)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
