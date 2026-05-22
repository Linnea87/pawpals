import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: Tab

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
                isSelected: selectedTab == .chat
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "\(icon).fill" : icon)
                    .font(.system(size: 22))
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
