import SwiftUI
import CoreLocation

struct MeetView: View {
    @Binding var selectedTab: Tab
    @Environment(MeetViewModel.self) private var viewModel
    
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
                                FilterChip(title: walkType.rawValue, isSelected:vm.activeFilters.contains(walkType.rawValue)) {
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
                    
                    if vm.isLocating {
                        Spacer()
                        VStack(spacing: Spacing.small) {
                            ProgressView()
                            Text("Finding your location...")
                                .font(.footnote)
                                .foregroundStyle(Theme.warmBrown.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                            
                    } else if
                        vm.locationStatus == .denied || vm.locationStatus == .restricted {
                        Spacer()
                        VStack(spacing: Spacing.medium) {
                            Image(systemName: "location.slash")
                                .font(.largeTitle)
                                .foregroundStyle(Theme.terracotta)
                            Text("Location access is off")
                                .font(.headline)
                                .foregroundStyle(Theme.warmBrown)
                            Text("PawPals needs your location to find nearby dogs.")
                                .font(.footnote)
                                .foregroundStyle(Theme.darkBrown.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.large)
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.terracotta)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                        
                        
                    } else if vm.isLoading {
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
            .task { await vm.loadWithLocation() }
            .sheet(item: $vm.selectedUser) { user in
                NavigationStack { ProfileView(user: user, isOwner: false, selectedTab: $selectedTab) }
            }
        }
    }
}

#Preview("Default") {
    MeetView(selectedTab: .constant(.meet))
        .environment(MeetViewModel(locationService: LocationService()))
}

#Preview("Active filters") {
    let vm: MeetViewModel = {
        let m = MeetViewModel(locationService: LocationService())
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
