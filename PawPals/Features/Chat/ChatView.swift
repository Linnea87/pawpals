import SwiftUI

struct ChatView: View {
    @Binding var selectedTab: Tab
    @Environment(ChatViewModel.self) private var chatVM
    @State private var navigationPath = NavigationPath()
    @State private var conversationVM = ConversationViewModel(
        conversationRepository: ConversationService()
    )
    var currentUserID: String = ""

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Theme.appBackground
                    .ignoresSafeArea()

                VStack(spacing: Spacing.none) {
                    filterTabs

                    if chatVM.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if chatVM.filteredConversations.isEmpty {
                        ContentUnavailableView(
                            "chat.noConversations",
                            systemImage: "bubble.left.and.bubble.right"
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(chatVM.filteredConversations) {
                            conversation in
                            NavigationLink(value: conversation) {
                                ConversationRowView(
                                    conversation: conversation,
                                    timestampText:
                                        chatVM.formattedTimeStamp(
                                            for: conversation
                                        ),
                                    otherUser: chatVM.otherUser(
                                        in: conversation,
                                        currentUserID: currentUserID
                                    ),
                                    unreadCount: conversation.unreadCounts[
                                        currentUserID,
                                        default: 0
                                    ]
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
                    otherUser: chatVM.otherUser(
                        in: conversation,
                        currentUserID: currentUserID
                    ) ?? .mock
                )
                .environment(conversationVM)
            }
            .safeAreaInset(edge: .bottom, spacing: Spacing.none) {
                TabBarView(
                    selectedTab: $selectedTab,
                    chatUnreadCount: chatVM.totalUnread
                )
            }
            .alert(
                "common.error",
                isPresented: Binding(
                    get: { chatVM.errorMessage != nil },
                    set: { if !$0 { chatVM.errorMessage = nil } }
                )
            ) {
                Button("common.ok") {
                    chatVM.errorMessage = nil
                }
            } message: {
                Text(chatVM.errorMessage ?? "")
            }
        }
        .task {
            chatVM.observeConversations(for: currentUserID)
            await chatVM.loadFavorites(for: currentUserID)
        }
        .onDisappear {
            chatVM.stopObservingConversations()
        }
        /// Handles the case where the notification tap arrives while the app is already open.
        .onChange(of: chatVM.pendingConversationID) { _, _ in
            navigateToPendingConversationIfNeeded()
        }
        /// Handles the case where the notification tap arrived before conversations were loaded.
        .onChange(of: chatVM.conversations) { _, _ in
            navigateToPendingConversationIfNeeded()
        }
    }

    private var filterTabs: some View {
        HStack(spacing: Spacing.small) {
            ForEach(ChatFilter.allCases, id: \.self) { filter in
                FilterChip(
                    title: NSLocalizedString(filter.label, comment: ""),
                    isSelected: chatVM.selectedFilter == filter
                ) {
                    chatVM.selectedFilter = filter
                }
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.medium)
    }

    // Navigates to the pending conversation if one is waiting AND conversations are loaded.
    private func navigateToPendingConversationIfNeeded() {
        guard let pendingID = chatVM.pendingConversationID,
            let conversation = chatVM.conversations.first(where: {
                $0.id == pendingID
            })
        else { return }
        navigationPath.append(conversation)
        chatVM.pendingConversationID = nil
    }

}

#Preview {
    ChatView(selectedTab: .constant(.chat), currentUserID: "Patrik")
        .environment(ChatViewModel.preview)
}
