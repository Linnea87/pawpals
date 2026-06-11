import SwiftUI
import CoreLocation

struct MeetView: View {
    @Binding var selectedTab: Tab
    @Environment(MeetViewModel.self) private var meetVM
    @Environment(AuthViewModel.self) private var authVM
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(LocationViewModel.self) private var locationVM
    @State private var showFilterSheet = false
    
    var body: some View {
        @Bindable var meetVM = meetVM
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("meet.header")
                        .font(.headline)
                        .fontWeight(.light)
                        .foregroundStyle(Theme.darkBrown)
                        .padding(.horizontal, Spacing.large)
                        .padding(.top, Spacing.large)
                        .padding(.bottom, Spacing.medium)
                    
                    if locationVM.isLocating {
                        Spacer()
                        VStack(spacing: Spacing.small) {
                            ProgressView()
                            Text("meet.findingLocation")
                                .font(.footnote)
                                .foregroundStyle(Theme.warmBrown.opacity(Opacity.xSmall))
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                        
                    } else if
                        locationVM.locationStatus == .denied || locationVM.locationStatus == .restricted {
                        Spacer()
                        VStack(spacing: Spacing.medium) {
                            Image(systemName: "location.slash")
                                .font(.largeTitle)
                                .foregroundStyle(Theme.terracotta)
                            Text("meet.location.accessOff")
                                .font(.headline)
                                .foregroundStyle(Theme.warmBrown)
                            Text("meet.location.accessDescription")
                                .font(.footnote)
                                .foregroundStyle(Theme.darkBrown.opacity(Opacity.xSmall))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.large)
                            Button(String(localized: "meet.location.openSettings")) {
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
                        
                        
                    } else if meetVM.isLoading {
                        
                        Spacer()
                        ProgressView()
                            .frame(maxWidth: .infinity)
                        Spacer()
                    } else if let error = meetVM.errorMessage {
                        Spacer()
                        Text(error)
                            .foregroundStyle(Theme.warmBrown)
                            .frame(maxWidth: .infinity)
                        Spacer()
                    } else if filterVM.applyFilters(to: meetVM.allNearbyUsers).isEmpty {
                        Spacer()
                        Text("meet.noMatches")
                            .foregroundStyle(Theme.darkBrown.opacity(Opacity.xSmall))
                            .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Spacing.medium) {
                                ForEach(filterVM.applyFilters(to: meetVM.allNearbyUsers)) { user in
                                    MeetCardView(user: user, isSaved: meetVM.savedUserIDs.contains(user.id))
                                        .onTapGesture { meetVM.selectedUser = user }
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
            
            .task { await meetVM.loadWithLocation(currentUserID: authVM.currentUserID) }
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
            
            .sheet(item: $meetVM.selectedUser) { user in
                ProfileView(user: user, isOwner: false, cameFromMeet: true, selectedTab: $selectedTab)
                    .environment(meetVM)
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView()
                    .environment(meetVM)
                    .environment(filterVM)
            }
        }
    }
}

#Preview("Default") {
    let locationVM = LocationViewModel()
    MeetView(selectedTab: .constant(.meet))
        .environment(MeetViewModel(locationViewModel: locationVM))
        .environment(FilterViewModel())
        .environment(locationVM)
        .environment(AuthViewModel(repository: MockAuthRepository(), profileRepository: MockProfileRepository()))
}

#Preview("Active filters") {
    let locationVM = LocationViewModel()
    let filterVM = FilterViewModel()
    filterVM.activeFilters = ["Evening walk", "City walk"]
    filterVM.activeSizeFilters = ["medium"]
    return MeetView(selectedTab: .constant(.meet))
        .environment(MeetViewModel(locationViewModel: locationVM))
        .environment(filterVM)
        .environment(locationVM)
        .environment(AuthViewModel(repository: MockAuthRepository(), profileRepository: MockProfileRepository()))
}
