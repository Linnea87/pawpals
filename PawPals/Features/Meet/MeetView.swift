import SwiftUI

struct MeetView: View {
    @Environment(MeetViewModel.self) private var viewModel
    
    var body: some View {
        @Bindable var vm = viewModel
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("Meet your new dog buddy")
                        .font(.headline)
                        .fontWeight(.light)
                        .foregroundStyle(Theme.darkBrown)
                        .padding(.horizontal, Spacing.large)
                        .padding(.top, Spacing.large)
                        .padding(.bottom, Spacing.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.small) {
                            FilterChip(title: "All", isSelected: vm.selectedFilter == nil) {
                                vm.selectFilter(nil)
                            }
                            ForEach(WalkType.allCases) { walkType in
                                FilterChip(title: walkType.rawValue, isSelected: vm.selectedFilter == walkType) {
                                    vm.selectFilter(walkType)
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.large)
                        .padding(.bottom, Spacing.large)
                    }
                    
                    if vm.isLoading {
                        Spacer()
                        ProgressView()
                            .frame(maxWidth: .infinity)
                        Spacer()
                    }
                    else if let error = vm.errorMessage {
                        Spacer()
                        Text(error)
                            .foregroundStyle(Theme.warmBrown)
                            .frame(maxWidth: .infinity)
                        Spacer()
                    }
                    else if vm.filteredUsers.isEmpty {
                        Spacer()
                        Text("No matches nearby")
                            .foregroundStyle(Theme.darkBrown.opacity(0.5))
                            .frame(maxWidth: .infinity)
                        Spacer()
                    }
                    
                    else {
                        ScrollView {
                            LazyVStack(spacing: Spacing.medium) {
                                ForEach(vm.filteredUsers) { user in
                                    ProfileCardView(user: user)
                                        .onTapGesture { vm.selectedUser = user }
                                }
                            }
                            .padding(.horizontal, Spacing.large)
                        }
                    }
                }
            }
            .task { await vm.loadNearbyUsers() }
            .sheet(item: $vm.selectedUser) { user in
                NavigationStack { ProfileView(user: user, isOwner: false) }
            }
        }
    }
}

#Preview {
    MeetView()
        .environment(MeetViewModel())
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.medium)
                .background(isSelected ? Theme.sageGreen : Theme.offWhite)
                .foregroundStyle(isSelected ? Theme.offWhite : Theme.darkBrown)
                .clipShape(Capsule())
        }
    }
}
