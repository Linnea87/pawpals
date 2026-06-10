import MapKit
import SwiftUI

struct FilterSheetView: View {
    @Environment(MeetViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authVM
    @Environment(FilterViewModel.self) private var filterViewModel
    @Environment(LocationViewModel.self) private var locationViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: Spacing.large) {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Walk type")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.darkBrown)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.small) {
                                FilterChip(title: "All", isSelected: filterViewModel.activeFilters.isEmpty) {
                                    filterViewModel.clearFilters(userID: authVM.currentUserID)
                                }
                                ForEach(WalkType.allCases) { walkType in
                                    FilterChip(
                                        title: walkType.rawValue,
                                        isSelected: filterViewModel.activeFilters.contains(walkType.rawValue)
                                    ) {
                                        filterViewModel.toggleFilter(walkType.rawValue, userID: authVM.currentUserID)

                                    }
                                }
                            }
                        }

                        Text("Dog size")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.darkBrown)
                            .padding(.top, Spacing.small)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.small) {
                                FilterChip(title: "All sizes", isSelected: filterViewModel.activeSizeFilters.isEmpty) {
                                    filterViewModel.clearSizeFilters(userID: authVM.currentUserID)
                                }
                                ForEach(DogSize.allCases, id: \.self) { size in
                                    FilterChip(
                                        title: size.rawValue.capitalized,
                                        isSelected: filterViewModel.activeSizeFilters.contains(size.rawValue)
                                    ) {
                                        filterViewModel.toggleSizeFilter(size.rawValue, userID: authVM.currentUserID)
                                    }
                                }
                            }
                        }
                    }
                    .padding(Spacing.medium)
                    .background(Theme.offWhite.opacity(Opacity.xSmall))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.medium))

                    VStack(alignment: .leading, spacing: Spacing.medium) {

                        ///  Radius slider
                        VStack(alignment: .leading, spacing: Spacing.small) {
                            Text("search.radius")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.darkBrown)

                            Text("\(Int(filterViewModel.searchRadius)) km")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.terracotta)

                            Slider(
                                value: Binding(
                                    get: { filterViewModel.searchRadius },
                                    set: { filterViewModel.setRadius(
                                            $0,
                                            userID: authVM.currentUserID
                                        )
                                    }
                                ),
                                in: 1...50,
                                step: 1
                            )
                            .tint(Theme.terracotta)

                            HStack {
                                Text("location.1km")
                                    .font(.caption)
                                    .foregroundStyle(Theme.sageGreen)
                                Spacer()
                                Text("location.50km")
                                    .font(.caption)
                                    .foregroundStyle(Theme.sageGreen)
                            }
                        }

                    
                        Divider()

                        /// Map fills the rest of the card
                        mapSection
                    }
                    .padding(Spacing.medium)
                    .background(Theme.offWhite.opacity(Opacity.xSmall))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
                    .frame(maxHeight: .infinity)
                }
                .padding(Spacing.medium)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.terracotta)
                }
            }
        }
    }

    @ViewBuilder
    private var mapSection: some View {
        if let center = locationViewModel.currentUserLocation {
            /// radius-only filter — walk type and size prefs do NOT affect the map
            let usersInRadius = viewModel.allNearbyUsers.filter {
                ($0.distance ?? 0) <= filterViewModel.searchRadius
            }

            Map(
                initialPosition: .region(
                    MKCoordinateRegion(
                        center: center,
                        latitudinalMeters: filterViewModel.searchRadius * 1000 * 2,
                        longitudinalMeters: filterViewModel.searchRadius * 1000 * 2
                    )
                )
            ) {
                UserAnnotation()

                
                ForEach(usersInRadius) { user in
                    if let lat = user.latitude, let lon = user.longitude {
                        Annotation(
                            user.name,
                            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        ) {
                            PawPinView()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
        } else {
            locationUnavailableView
        }
    }

    private var locationUnavailableView: some View {
        HStack {
            Spacer()
            VStack(spacing: Spacing.small) {
                Image(systemName: "location.slash")
                    .font(.title2)
                    .foregroundStyle(Theme.sageGreen)
                Text("location.unavailable")
                    .font(.subheadline)
                    .foregroundStyle(Theme.sageGreen)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.offWhite.opacity(Opacity.xSmall))
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
    }
    
    private struct PawPinView: View {
        var body: some View {
            Image(systemName: "pawprint.fill")
                .font(.title3)
                .foregroundStyle(Theme.terracotta)
                .padding(Spacing.xSmall)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: Radius.xxSmall)
        }
    }
}

#Preview {
    let locationVM: LocationViewModel = {
        let vm = LocationViewModel()
        vm.currentUserLocation = CLLocationCoordinate2D(latitude: 59.3293, longitude: 18.0686)
        return vm
    }()
    let meetVM: MeetViewModel = {
        let vm = MeetViewModel(meetRepository: MockMeetRepository(), locationViewModel: locationVM)
        vm.allNearbyUsers = User.mockUsers
        return vm
    }()

    FilterSheetView()
        .environment(meetVM)
        .environment(locationVM)
        .environment(FilterViewModel())
        .environment(AuthViewModel(repository: AuthService(), profileRepository: ProfileService()))
}
