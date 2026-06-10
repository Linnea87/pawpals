import SwiftUI
import CoreLocation

struct MeetView: View {
    @Binding var selectedTab: Tab
    @Environment(MeetViewModel.self) private var viewModel
    @Environment(FilterViewModel.self) private var filterViewModel
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
                    
                    if vm.isLocating {
                        Spacer()
                        VStack(spacing: Spacing.small) {
                            ProgressView()
                            Text("Finding your location...")
                                .font(.footnote)
                                .foregroundStyle(Theme.warmBrown.opacity(Opacity.xSmall))
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
                                .foregroundStyle(Theme.darkBrown.opacity(Opacity.xSmall))
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
                    } else if let error = vm.errorMessage {
                        Spacer()
                        Text(error)
                            .foregroundStyle(Theme.warmBrown)
                            .frame(maxWidth: .infinity)
                        Spacer()
                    } else if filterViewModel.applyFilters(to: vm.allNearbyUsers).isEmpty {
                        Spacer()
                        Text("No matches nearby")
                            .foregroundStyle(Theme.darkBrown.opacity(Opacity.xSmall))
                            .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Spacing.medium) {
                                ForEach(filterViewModel.applyFilters(to: vm.allNearbyUsers)) { user in
                                    MeetCardView(user: user, isSaved: vm.savedUserIds.contains(user.id))
                                        .onTapGesture { vm.selectedUser = user }
                                }
                            }
                            .padding(.horizontal, Spacing.xLarge)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: Spacing.none) {
                TabBarView(selectedTab: $selectedTab)
            }
            
            .task { await vm.loadWithLocation() }
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
                ProfileView(user: user, isOwner: false, selectedTab: $selectedTab)
                    .environment(viewModel)
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView()
                    .environment(viewModel)
                    .environment(filterViewModel)
            }
        }
    }
}

#Preview("Default") {
    MeetView(selectedTab: .constant(.meet))
        .environment(MeetViewModel(locationService: LocationService()))
}

#Preview("Active filters") {
    let vm = MeetViewModel(locationService: LocationService())
    let filterVM = FilterViewModel()
    filterVM.activeFilters = ["Evening walk", "City walk"]
    filterVM.activeSizeFilters = ["medium"]
    return MeetView(selectedTab: .constant(.meet))
        .environment(vm)
        .environment(filterVM)
}
