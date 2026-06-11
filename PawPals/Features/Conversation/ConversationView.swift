import PhotosUI
import SwiftUI

struct ConversationView: View {
    @Environment(ConversationViewModel.self) private var conversationViewModel
    @Environment(ChatViewModel.self) private var chatViewModel
    @Environment(\.dismiss) private var dismiss
    let conversation: Conversation
    let currentUserID: String
    let otherUser: User
    var isModal: Bool = false

    var selectedTab: Binding<Tab> = .constant(.chat)

    @State private var selectedUser: User?

    var body: some View {
        @Bindable var conversationVM = conversationViewModel

        ZStack {
            Theme.appBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.none) {
                if conversationVM.isLoading {
                    Spacer()
                    ProgressView()
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: Spacing.small) {
                                DateSeparatorView(date: Date())

                                ForEach(conversationVM.messages) { message in
                                    MessageBubbleView(
                                        message: message,
                                        isFromCurrentUser: message.senderID
                                            == currentUserID
                                    )
                                    .id(message.id)
                                }
                                // TODO [PP-028]: Remove temporary uploading placeholder message
                                // when real message with imageURL arrives from Firestore observer
                                if conversationVM.isUploadingImage {
                                    MessageBubbleView(
                                        message: Message(
                                            id: "uploading",
                                            senderID: currentUserID,
                                            receiverID: "",
                                            text: "",
                                            timestamp: Date()
                                        ),
                                        isFromCurrentUser: true,
                                        isUploadingImage: true
                                    )
                                }
                            }
                            .padding(Spacing.medium)
                        }
                        .onChange(of: conversationVM.messages.count) { _, _ in
                            guard let last = conversationVM.messages.last else {
                                return
                            }
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                MessageInputBar(text: $conversationVM.messageText) {
                    Task {
                        await conversationVM.sendMessage(
                            in: conversation,
                            senderID: currentUserID
                        )
                    }
                } onImagePick: { image in
                    Task {
                        await conversationVM.sendImage(
                            image,
                            in: conversation,
                            senderID: currentUserID
                        )
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                Button {
                    selectedUser = otherUser
                } label: {
                    VStack(spacing: Spacing.xxSmall) {
                        AvatarView(
                            photoURL: otherUser.photoURL,
                            size: IconSize.messageAvatar,
                            iconSize:
                                IconSize.avatarIconSmall
                        )

                        Text(otherUser.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.darkBrown)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if isModal {
                        chatViewModel.activeConversation = nil
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Theme.warmBrown)
                }
            }
        })
        .sheet(item: $selectedUser) { user in
            NavigationStack {
                ProfileView(
                    user: user,
                    isOwner: false,
                    cameFromMeet: false,
                    selectedTab: .constant(.chat)
                )
            }
        }
        .toolbarVisibility(.hidden, for: .tabBar)
        .onAppear {
            conversationViewModel.observeMessages(
                conversationID: conversation.id,
                currentUserID: currentUserID
            )
            Task {
                guard !conversationViewModel.isNew else { return }
                await conversationViewModel.markAsRead(
                    conversationID: conversation.id,
                    userID: currentUserID
                )
            }
        }
        .onDisappear {
            conversationViewModel.stopObservingMessages()
        }
        .alert(
            String(localized: "common.error"),
            isPresented: Binding(
                get: { conversationVM.errorMessage != nil },
                set: { if !$0 { conversationVM.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "common.ok")) {
                conversationVM.errorMessage = nil
            }
        } message: {
            Text(conversationVM.errorMessage ?? "")
        }
    }
}

#Preview {
    let conversationViewModel = ConversationViewModel(
        conversationRepository: MockConversationRepository()
    )
    let conversation = Conversation(
        id: "conv1",
        participantIDs: ["user1", "user2"],
        lastMessage: "Can't wait! See you there",
        lastMessageTimestamp: Date().addingTimeInterval(-60)
    )
    NavigationStack {
        ConversationView(
            conversation: conversation,
            currentUserID: "user1",
            otherUser: .mock
        )
    }

    .environment(conversationViewModel)
    .environment(
        ChatViewModel(
            chatRepository: MockChatRepository(),
            profileRepository: MockProfileRepository(),
            meetRepository: MockMeetRepository()
        )
    )
    .environment(
        AuthViewModel(
            repository: MockAuthRepository(),
            profileRepository: MockProfileRepository()
        )
    )
    .environment(
        ProfileViewModel(
            profileRepository: MockProfileRepository(),
            user: .mock
        )
    )
}
