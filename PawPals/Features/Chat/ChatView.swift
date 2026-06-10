import SwiftUI



struct ChatView: View {
    @Binding var selectedTab: Tab
    @Environment(ChatViewModel.self) private var chatViewModel
    @State private var navigationPath = NavigationPath()
    @State private var conversationViewModel = ConversationViewModel(conversationRepository: ConversationService())
    var currentUserID: String = ""

    

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Theme.appBackground
                    .ignoresSafeArea()

                VStack(spacing: Spacing.none) {
                    filterTabs

                    if chatViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if chatViewModel.filteredConversations.isEmpty {
                        ContentUnavailableView(
                            "chat.noConversations",
                            systemImage: "bubble.left.and.bubble.right"
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(chatViewModel.filteredConversations) { conversation in
                            NavigationLink(value: conversation) {
                                ConversationRowView(
                                    conversation: conversation,
                                    timestampText: chatViewModel.formattedTimeStamp(for: conversation),
                                    otherUser: chatViewModel.otherUser(in: conversation, currentUserID: currentUserID)
                                )
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(
                                EdgeInsets(
                                    top: Spacing.small,
                                    leading: Spacing.medium,
                                    bottom: Spacing.small,
                                    trailing: Spacing.medium
                                )
                            )
                        }
                        .scrollContentBackground(.hidden)
                    }

                }

            }
            .navigationDestination(for: Conversation.self) { conversation in
                ConversationView(
                    conversation: conversation,
                    currentUserID: currentUserID,
                    otherUser: chatViewModel.otherUser(in: conversation, currentUserID: currentUserID) ?? .mock
                )
                .environment(conversationViewModel)
            }
            .safeAreaInset(edge: .bottom, spacing: Spacing.none) {
                TabBarView(
                    selectedTab: $selectedTab,
                    chatUnreadCount: chatViewModel.totalUnread
                )
            }
            .alert(
                "common.error",
                isPresented: .constant(chatViewModel.errorMessage != nil)
            ) {
                Button("common.ok") {}
            } message: {
                Text(chatViewModel.errorMessage ?? "")
            }
        }
        .task {
            chatViewModel.observeConversations(for: currentUserID)
            await chatViewModel.loadFavorites(for: currentUserID)
        }
        .onDisappear {
            chatViewModel.stopObservingConversations()
        }
        /// Handles the case where the notification tap arrives while the app is already open.
        .onChange(of: chatViewModel.pendingConversationID) { _, _ in
            navigateToPendingConversationIfNeeded()
        }
        /// Handles the case where the notification tap arrived before conversations were loaded.
        .onChange(of: chatViewModel.conversations) { _, _ in
            navigateToPendingConversationIfNeeded()
        }
    }

    private var filterTabs: some View {
        HStack(spacing: Spacing.small) {
            ForEach(ChatFilter.allCases, id: \.self) { filter in
                FilterChip(
                    title: NSLocalizedString(filter.label, comment: ""),
                    isSelected: chatViewModel.selectedFilter == filter
                ) {
                    chatViewModel.selectedFilter = filter
                }
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.medium)
    }

    // Navigates to the pending conversation if one is waiting AND conversations are loaded.
    private func navigateToPendingConversationIfNeeded() {
        guard let pendingID = chatViewModel.pendingConversationID,
            let conversation = chatViewModel.conversations.first(where: {
                $0.id == pendingID
            })
        else { return }
        navigationPath.append(conversation)
        chatViewModel.pendingConversationID = nil
    }

}

private func makePreviewChatViewModel() -> ChatViewModel {
    let viewModel = ChatViewModel(chatRepository: MockChatRepository(), profileRepository: MockProfileRepository(), meetRepository: MockMeetRepository())
    viewModel.conversations = [
        Conversation(
            id: "1",
            participantIDs: ["Anna", "Patrik"],
            lastMessage: "Hey, want to go for a walk?",
            lastMessageTimestamp: Date(),
            unreadCount: 3
        ),
        Conversation(
            id: "2",
            participantIDs: ["Sara", "Patrik"],
            lastMessage: "My dog loved meeting yours!",
            lastMessageTimestamp: Date().addingTimeInterval(-3600),
            unreadCount: 1
        ),
        Conversation(
            id: "3",
            participantIDs: ["Johan", "Patrik"],
            lastMessage: "See you at the park!",
            lastMessageTimestamp: Date().addingTimeInterval(-7200)
        )
    ]
    return viewModel
}

#Preview {
    ChatView(selectedTab: .constant(.chat), currentUserID: "Patrik")
        .environment(makePreviewChatViewModel())
}
