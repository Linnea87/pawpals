import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: Tab
    var chatUnreadCount: Int = 0

    var body: some View {
        HStack(spacing: 0) {
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
        .padding(.top, 8)
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
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "\(icon).fill" : icon)
                    .font(.system(size: 22))
                    .overlay(alignment: .topTrailing) {
                        if badge > 0 {
                            Text("\(badge)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(3)
                                .background(Theme.terracotta)
                                .clipShape(Circle())
                                .offset(x: 8, y: -6)
                        }
                    }
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(isSelected ? Theme.sageGreen : Theme.mediumSage)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    @Previewable @State var selectedTab: Tab = .profile
    TabBarView(selectedTab: $selectedTab)
}
