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

private struct DateSeparatorView: View {
    let date: Date

    private var label: LocalizedStringKey {
        if Calendar.current.isDateInToday(date) { return "date.today" }
        if Calendar.current.isDateInYesterday(date) { return "date.yesterday" }
        return LocalizedStringKey(
            date.formatted(date: .abbreviated, time: .omitted)
        )
    }

    var body: some View {
        Text(label)
            .font(.caption)
            .foregroundStyle(Theme.warmBrown)
            .padding(.vertical, Spacing.small)
    }
}

private struct MessageBubbleView: View {
    let message: Message
    let isFromCurrentUser: Bool
    var isUploadingImage: Bool = false

    var body: some View {
        HStack {
            if !isFromCurrentUser {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    bubbleContent
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(Theme.warmBrown)
                }
                Spacer()
            } else {
                Spacer()
                VStack(alignment: .trailing, spacing: Spacing.xSmall) {
                    bubbleContent

                    HStack(spacing: Spacing.xSmall) {
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundStyle(Theme.warmBrown)
                        MessageStatusView(
                            isDelivered: message.isDelivered,
                            isRead: message.isRead
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        if isUploadingImage {
            ProgressView()
                .frame(width: Size.imagePreview, height: Size.imagePlaceholder)
                .background(
                    isFromCurrentUser
                        ? Theme.terracotta.opacity(Opacity.xxSmall)
                        : Theme.offWhite
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.medium))

        } else if let imageURL = message.imageURL,
            let url = URL(string: imageURL)
        {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().frame(width: Size.imagePreview, height: Size.imagePlaceholder)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: Size.imagePreview, maxHeight: Size.imagePreview)
                            .clipShape(
                                RoundedRectangle(cornerRadius: Radius.medium)
                            )
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundStyle(Theme.warmBrown)
                            .frame(width: Size.imagePreview, height: Size.imagePlaceholder)
                    @unknown default:
                        EmptyView()
                    }
                }
                if !message.text.isEmpty {
                    Text(message.text)
                        .padding(.horizontal, Spacing.medium)
                        .padding(.vertical, Spacing.small)
                        .background(
                            isFromCurrentUser
                                ? Theme.terracotta : Theme.offWhite
                        )
                        .foregroundStyle(
                            isFromCurrentUser ? .white : Theme.darkBrown
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: Radius.medium)
                        )
                }
            }

        } else {
            Text(message.text)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(
                    isFromCurrentUser ? Theme.terracotta : Theme.offWhite
                )
                .foregroundStyle(isFromCurrentUser ? .white : Theme.darkBrown)
                .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
        }
    }
}

private struct MessageStatusView: View {
    let isDelivered: Bool
    let isRead: Bool

    var body: some View {
        HStack(spacing: Spacing.negativeXSmall) {
            Image(systemName: "checkmark")
                .font(.system(size: FontSize.small, weight: .semibold))
                .foregroundStyle(isRead ? Theme.terracotta : Theme.warmBrown)
            Image(systemName: "checkmark")
                .font(.system(size: FontSize.small, weight: .semibold))
                .foregroundStyle(isRead ? Theme.terracotta : Theme.warmBrown)
                .opacity(isDelivered || isRead ? 1 : 0)
        }
    }
}

private struct MessageInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    let onImagePick: (UIImage) -> Void

    // TODO [PP-028]: Reset selectedPhoto after upload
    // so user can pick the same image twice
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        HStack(spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {

                TextField("chat.messagePlaceholder", text: $text)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(Theme.offWhite)
            .clipShape(Capsule())

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Image(systemName: "photo")
                    .font(.system(size: Spacing.large, weight: .semibold))
                    .foregroundStyle(Theme.warmBrown)
                    .padding(Spacing.medium)
                    .background(Theme.lightPeach)
                    .clipShape(Circle())
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(
                        type: Data.self
                    ),
                        let image = UIImage(data: data)
                    {
                        onImagePick(image)
                        selectedPhoto = nil
                    }
                }
            }

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: Spacing.large, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(Spacing.medium)
                    .background(
                        text.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Theme.sageGreen
                            : Theme.terracotta
                    )
                    .clipShape(Circle())
            }
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.medium)

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
