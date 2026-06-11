import SwiftUI

struct MessageBubbleView: View {
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
                        ProgressView().frame(
                            width: Size.imagePreview,
                            height: Size.imagePlaceholder
                        )
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(
                                maxWidth: Size.imagePreview,
                                maxHeight: Size.imagePreview
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: Radius.medium)
                            )
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundStyle(Theme.warmBrown)
                            .frame(
                                width: Size.imagePreview,
                                height: Size.imagePlaceholder
                            )
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

