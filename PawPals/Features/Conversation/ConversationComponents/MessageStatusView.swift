import SwiftUI

struct MessageStatusView: View {
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
