import SwiftUI

struct AppNavigationView: View {

    @Environment(AuthViewModel.self) private var authVM
    @Environment(ChatViewModel.self) private var chatViewModel
    @Environment(NotificationService.self) private var notificationService
    @State private var selectedTab: Tab = .meet

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                switch selectedTab {
                case .profile:
                    if let user = authVM.currentUser {
                        ProfileView(user: user, isOwner: true, selectedTab: $selectedTab)
                    }
                case .chat:
                    ChatView(
                        selectedTab: $selectedTab,
                        currentUserID: authVM.currentUserId
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
        // Fires when the user taps a push notification.
        // Passes the conversationID to ChatViewModel and switches to the chat tab.
        .onChange(of: notificationService.pendingConversationID) { _, conversationID in
            guard let conversationID else { return }
            chatViewModel.pendingConversationID = conversationID
            selectedTab = .chat
            notificationService.pendingConversationID = nil
        }
        // Fires once after the user signs in.
        // Requests notification permission and saves the token to Firestore.
        .onChange(of: authVM.isAuthenticated) { _, isAuthenticated in
            guard isAuthenticated else { return }
            Task {
                await notificationService.requestPermission()
                if let token = notificationService.pushNotificationToken {
                    await notificationService.savePushNotificationToken(
                        token,
                        for: authVM.currentUserId
                    )
                }
            }
        }
    }
}
