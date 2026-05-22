import SwiftUI

struct TabBarView: View {
    @State private var selectedTab: Tab = .meet

    enum Tab: CaseIterable {
        case profile, chat, meet

        var label: LocalizedStringKey {
            switch self {
            case .profile: return "tab.profile"
            case .chat:    return "tab.chat"
            case .meet:    return "tab.meet"
            }
        }

        var icon: String {
            switch self {
            case .profile: return "person"
            case .chat:    return "bubble.left"
            case .meet:    return "pawprint"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .profile:
                    NavigationStack { ProfileView(user: .mock, isOwner: true) }
                case .chat:
                    NavigationStack { ChatView() }
                case .meet:
                    NavigationStack { MeetView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}


private struct CustomTabBar: View {
    @Binding var selectedTab: TabBarView.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabBarView.Tab.allCases, id: \.self) { tab in
                CustomTabItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }
}


private struct CustomTabItem: View {
    let tab: TabBarView.Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(isSelected ? Theme.offWhite : Theme.sageGreen)

                Text(tab.label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isSelected ? Theme.offWhite : Theme.sageGreen)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? AnyShapeStyle(Theme.activeTabBar) : AnyShapeStyle(Color.clear))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.3), value: isSelected)
    }
}
#Preview {
    TabBarView()
}
