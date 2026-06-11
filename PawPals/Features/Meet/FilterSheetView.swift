import MapKit
import SwiftUI

struct FilterSheetView: View {
    @Environment(MeetViewModel.self) private var meetVM
    @Environment(AuthViewModel.self) private var authVM
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(LocationViewModel.self) private var locationVM
    @Environment(\.dismiss) private var dismiss

    @State private var debounceTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: Spacing.large) {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("meet.filter.walkType")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.darkBrown)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.small) {
                                FilterChip(
                                    title: String(localized: "meet.filter.all"),
                                    isSelected: filterVM.activeFilters.isEmpty
                                ) {
                                    filterVM.clearFilters(
                                        userID: authVM.currentUserID
                                    )
                                }
                                ForEach(WalkType.allCases) { walkType in
                                    FilterChip(
                                        title: walkType.displayName,
                                        isSelected: filterVM.activeFilters
                                            .contains(walkType.rawValue)
                                    ) {
                                        filterVM.toggleFilter(
                                            walkType.rawValue,
                                            userID: authVM.currentUserID
                                        )

                                    }
                                }
                            }
                        }

                        Text("meet.filter.dogSize")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.darkBrown)
                            .padding(.top, Spacing.small)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.small) {
                                FilterChip(
                                    title: String(
                                        localized: "meet.filter.allSizes"
                                    ),
                                    isSelected: filterVM.activeSizeFilters
                                        .isEmpty
                                ) {
                                    filterVM.clearSizeFilters(
                                        userID: authVM.currentUserID
                                    )
                                }
                                ForEach(DogSize.allCases, id: \.self) { size in
                                    FilterChip(
                                        title: size.displayName,
                                        isSelected: filterVM.activeSizeFilters
                                            .contains(size.rawValue)
                                    ) {
                                        filterVM.toggleSizeFilter(
                                            size.rawValue,
                                            userID: authVM.currentUserID
                                        )
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

                            Text("\(Int(filterVM.searchRadius)) km")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.terracotta)

                            Slider(
                                value: Binding(
                                    get: { filterVM.searchRadius },
                                    set: {
                                        filterVM.setRadius(
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
        .onChange(of: filterVM.searchRadius) { _, newRadius in
            debounceTask?.cancel()

            debounceTask = Task {
                try? await Task.sleep(for: .seconds(0.6))
                guard !Task.isCancelled else { return }
                await meetVM.loadNearbyUsers(
                    currentUserID: authVM.currentUserID,
                    radius: newRadius
                )
            }
        }
    }

    @ViewBuilder
    private var mapSection: some View {
        if let center = locationVM.currentUserLocation {
            /// radius-only filter — walk type and size prefs do NOT affect the map
            let usersInRadius = meetVM.allNearbyUsers.filter {
                ($0.distance ?? 0) <= filterVM.searchRadius
            }

            Map(
                initialPosition: .region(
                    MKCoordinateRegion(
                        center: center,
                        latitudinalMeters: filterVM.searchRadius * 1000 * 2,
                        longitudinalMeters: filterVM.searchRadius * 1000 * 2
                    )
                )
            ) {
                UserAnnotation()

                ForEach(usersInRadius) { user in
                    if let lat = user.latitude, let lon = user.longitude {
                        Annotation(
                            user.name,
                            coordinate: CLLocationCoordinate2D(
                                latitude: lat,
                                longitude: lon
                            )
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
        vm.currentUserLocation = CLLocationCoordinate2D(
            latitude: 59.3293,
            longitude: 18.0686
        )
        return vm
    }()
    let meetVM: MeetViewModel = {
        let vm = MeetViewModel(
            meetRepository: MockMeetRepository(),
            locationViewModel: locationVM
        )
        vm.allNearbyUsers = User.mockUsers
        return vm
    }()

    FilterSheetView()
        .environment(meetVM)
        .environment(locationVM)
        .environment(FilterViewModel())
        .environment(
            AuthViewModel(
                repository: AuthService(),
                profileRepository: ProfileService()
            )
        )
}
