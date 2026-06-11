import SwiftUI

struct AppNavigationView: View {

    @Environment(AuthViewModel.self) private var authVM
    @Environment(ChatViewModel.self) private var chatVM
    @Environment(NotificationService.self) private var notificationService
    @Environment(LocationViewModel.self) private var locationVM
    @Environment(ProfileViewModel.self) private var profileVM
    
    @State private var selectedTab: Tab = .meet

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                switch selectedTab {
                case .profile:
                    if let user = authVM.currentUser {
                        ProfileView(user: user, isOwner: true, cameFromMeet: false, selectedTab: $selectedTab)
                    }
                case .chat:
                    ChatView(
                        selectedTab: $selectedTab,
                        currentUserID: authVM.currentUserID
                    )
                case .meet:
                    MeetView(selectedTab: $selectedTab)
                }
            } else {
                NavigationStack {
                    AuthView()
                }
            }
        }
        
        .onChange(of: locationVM.resolvedCity) { _, city in
            if let city {
                profileVM.user.city = city
            }
        }
        .onChange(of: notificationService.pendingConversationID) { _, conversationID in
            guard let conversationID else { return }
            chatVM.pendingConversationID = conversationID
            selectedTab = .chat
            notificationService.pendingConversationID = nil
        }
        /// Fires once after the user signs in.
        /// Requests notification permission and saves the token to Firestore.
        .onChange(of: authVM.isAuthenticated) { _, isAuthenticated in
            guard isAuthenticated else { return }
            Task {
                await notificationService.requestPermission()
                if let token = notificationService.pushNotificationToken {
                    await notificationService.savePushNotificationToken(
                        token,
                        for: authVM.currentUserID
                    )
                }
            }
        }
        .onChange(of: notificationService.pushNotificationToken) { _, token in
            guard let token, let userID = authVM.currentUser?.id else { return }
            Task {
                await notificationService.savePushNotificationToken(token, for: userID)
            }
        }
    }
}
