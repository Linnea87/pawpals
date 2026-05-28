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
                    ProfileView(
                        user: .mock,
                        isOwner: true,
                        selectedTab: $selectedTab
                    )
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
        .onChange(of: notificationService.pendingConversationID) { _, conversationID in
            guard let conversationID else { return }
            chatViewModel.pendingConversationID = conversationID
            selectedTab = .chat
            notificationService.pendingConversationID = nil
        }
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

