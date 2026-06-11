import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct PawPalsApp: App {
    @State private var authVM: AuthViewModel
    @State private var meetVM: MeetViewModel
    @State private var chatVM: ChatViewModel
    @State private var notificationService: NotificationService
    @State private var locationVM: LocationViewModel
    @State private var profileVM: ProfileViewModel
    @State private var filterVM: FilterViewModel


    init() {
        FirebaseApp.configure()

        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }

        let locationVM = LocationViewModel()
        _locationVM = State(initialValue: locationVM)
        _meetVM = State(initialValue: MeetViewModel(locationViewModel: locationVM))
        _authVM = State(initialValue: AuthViewModel(repository: AuthService(), profileRepository: ProfileService()))
        _chatVM = State(initialValue: ChatViewModel(chatRepository: ChatService(), profileRepository: ProfileService(), meetRepository: MeetService()))
        _notificationService = State(initialValue: NotificationService(profileRepository: ProfileService()))
        _profileVM = State(initialValue: ProfileViewModel(profileRepository: ProfileService(), user: .mock))
        _filterVM = State(initialValue: FilterViewModel())
    }

    var body: some Scene {
        WindowGroup {
            AppNavigationView()
                .environment(authVM)
                .environment(meetVM)
                .environment(filterVM)
                .environment(chatVM)
                .environment(notificationService)
                .environment(locationVM)
                .environment(profileVM)
                .onChange(of: authVM.currentUser?.id) { _, _ in
                     if let user = authVM.currentUser {
                         profileVM.user = user
                         Task { await profileVM.loadUser(userID: user.id) }
                     } else {
                         profileVM.user = .mock
                     }
                 }

                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
