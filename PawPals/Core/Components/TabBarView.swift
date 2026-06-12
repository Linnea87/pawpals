import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: Tab
    var chatUnreadCount: Int = 0

    var body: some View {
        HStack(spacing: Spacing.none) {
            CustomTabItem(
                label: String(localized: "profile.tab"),
                icon: "person",
                isSelected: selectedTab == .profile
            ) { selectedTab = .profile }

            CustomTabItem(
                label: String(localized: "chat.tab"),
                icon: "bubble.left",
                isSelected: selectedTab == .chat,
                badge: chatUnreadCount
            ) { selectedTab = .chat }

            CustomTabItem(
                label: String(localized: "meet.tab"),
                icon: "pawprint",
                isSelected: selectedTab == .meet
            ) { selectedTab = .meet }
        }
        .padding(.top, Spacing.small)
        .background(Theme.offWhite)
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct CustomTabItem: View {
    let label: String
    let icon: String
    let isSelected: Bool
    var badge: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xSmall) {
                Image(systemName: isSelected ? "\(icon).fill" : icon)
                    .font(.system(size: IconSize.tabBarIcon))
                    .overlay(alignment: .topTrailing) {
                        if badge > 0 {
                            Text("\(badge)")
                                .font(
                                    .system(
                                        size: FontSize.xxSmall,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(.white)
                                .padding(Spacing.xSmall)
                                .background(Theme.terracotta)
                                .clipShape(Circle())
                                .offset(
                                    x: Spacing.small,
                                    y: Spacing.negativeSmall
                                )
                        }
                    }
                Text(label.uppercased())
                    .font(.system(size: FontSize.xSmall, weight: .semibold))
            }
            .foregroundStyle(isSelected ? Theme.sageGreen : Theme.mediumSage)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.small)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: Duration.standard), value: isSelected)
    }
}

#Preview {
    @Previewable @State var selectedTab: Tab = .profile
    TabBarView(selectedTab: $selectedTab)
}

