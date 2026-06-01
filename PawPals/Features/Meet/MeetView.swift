import SwiftUI

struct MeetView: View {
    @Binding var selectedTab: Tab
    @Environment(MeetViewModel.self) private var viewModel
    @State private var showFilterSheet = false

    var body: some View {
        @Bindable var vm = viewModel
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("Meet your new dog buddy!")
                        .font(.headline)
                        .fontWeight(.light)
                        .foregroundStyle(Theme.darkBrown)
                        .padding(.horizontal, Spacing.large)
                        .padding(.top, Spacing.large)
                        .padding(.bottom, Spacing.medium)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.small) {
                            FilterChip(title: "All", isSelected: vm.activeFilters.isEmpty) {
                                vm.clearFilters()
                            }
                            ForEach(WalkType.allCases) { walkType in
                                FilterChip(title: walkType.rawValue, isSelected: vm.activeFilters.contains(walkType.rawValue)) {
                                    vm.toggleFilter(walkType.rawValue)
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.large)
                        .padding(.bottom, Spacing.large)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.small) {
                            FilterChip(title: "All sizes", isSelected: vm.activeSizeFilters.isEmpty) {
                                vm.clearSizeFilters()
                            }
                            ForEach(DogSize.allCases, id: \.self) { size in
                                FilterChip(title: size.rawValue.capitalized, isSelected: vm.activeSizeFilters.contains(size.rawValue)) {
                                    vm.toggleSizeFilter(size.rawValue)
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
                    } else if let error = vm.errorMessage {
                        Spacer()
                        Text(error)
                            .foregroundStyle(Theme.warmBrown)
                            .frame(maxWidth: .infinity)
                        Spacer()
                    } else if vm.filteredUsers.isEmpty {
                        Spacer()
                        Text("No matches nearby")
                            .foregroundStyle(Theme.darkBrown.opacity(0.5))
                            .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Spacing.medium) {
                                ForEach(vm.filteredUsers) { user in
                                    MeetCardView(user: user)
                                        .onTapGesture { vm.selectedUser = user }
                                }
                            }
                            .padding(.horizontal, Spacing.large)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                TabBarView(selectedTab: $selectedTab)
            }
            .task { await vm.loadNearbyUsers() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(Theme.darkBrown)
                    }
                }
            }
            .sheet(item: $vm.selectedUser) { user in
                NavigationStack {
                    ProfileView(user: user, isOwner: false, selectedTab: $selectedTab)
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView()
                    .environment(viewModel)
            }
        }
    }
}

#Preview("Default") {
    MeetView(selectedTab: .constant(.meet))
        .environment(MeetViewModel())
}

#Preview("Active filters") {
    let vm: MeetViewModel = {
        let m = MeetViewModel()
        m.activeFilters = ["Evening walk", "City walk"]
        m.activeSizeFilters = ["medium"]
        m.filteredUsers = [.mock]
        return m
    }()
    MeetView(selectedTab: .constant(.meet))
        .environment(vm)
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
