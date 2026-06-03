import MapKit
import SwiftUI

struct FilterSheetView: View {
    @Environment(MeetViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: Spacing.large) {
                    // Preference chips/pills card can go here later (above the slider+map card)
                    Spacer()

                    VStack(alignment: .leading, spacing: Spacing.medium) {

                        ///  Radius slider
                        VStack(alignment: .leading, spacing: Spacing.small) {
                            Text("search.radius")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.darkBrown)

                            Text("\(Int(viewModel.searchRadius)) km")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.terracotta)

                            Slider(
                                value: Binding(
                                    get: { viewModel.searchRadius },
                                    set: {
                                        viewModel.setRadius(
                                            $0,
                                            userId: authVM.currentUserId
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
                    .background(Theme.offWhite.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
                    .frame(maxHeight: .infinity)
                }
                .padding(Spacing.medium)
            }
            .navigationTitle("common.filter")
            .navigationBarTitleDisplayMode(.inline)
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
        if let center = viewModel.currentUserLocation {
            /// radius-only filter — walk type and size prefs do NOT affect the map
            let usersInRadius = viewModel.allNearbyUsers.filter {
                ($0.distance ?? 0) <= viewModel.searchRadius
            }

            Map(
                initialPosition: .region(
                    MKCoordinateRegion(
                        center: center,
                        latitudinalMeters: viewModel.searchRadius * 1000 * 2,
                        longitudinalMeters: viewModel.searchRadius * 1000 * 2
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
        .background(Theme.offWhite.opacity(Opacity.xSmal))
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
    let vm = MeetViewModel(userRepository: MockUserRepository(), locationService: LocationService())
    vm.currentUserLocation = CLLocationCoordinate2D(latitude: 59.3293, longitude: 18.0686)
    vm.allNearbyUsers = [
        // ~2 km north — visible at low radius
        User.mock,
        // ~5 km east
        User(
            id: "preview-2",
            name: "Erik",
            photoURL: nil,
            bio: "",
            city: "Stockholm",
            dogs: [],
            preferences: UserPreferences(walkTypes: [.evening], dogSize: .medium, searchRadius: 10.0),
            distance: 5.0,
            latitude: 59.3300,
            longitude: 18.1400
        ),
        // ~10 km south-west
        User(
            id: "preview-3",
            name: "Lisa",
            photoURL: nil,
            bio: "",
            city: "Stockholm",
            dogs: [],
            preferences: UserPreferences(walkTypes: [.forest], dogSize: .small, searchRadius: 10.0),
            distance: 10.0,
            latitude: 59.2500,
            longitude: 17.9800
        ),
        // ~18 km north-west
        User(
            id: "preview-4",
            name: "Johan",
            photoURL: nil,
            bio: "",
            city: "Solna",
            dogs: [],
            preferences: UserPreferences(walkTypes: [.morning], dogSize: .large, searchRadius: 20.0),
            distance: 18.0,
            latitude: 59.4200,
            longitude: 17.9000
        ),
        // ~30 km south — only visible at max radius
        User(
            id: "preview-5",
            name: "Anna",
            photoURL: nil,
            bio: "",
            city: "Huddinge",
            dogs: [],
            preferences: UserPreferences(walkTypes: [.evening], dogSize: .medium, searchRadius: 30.0),
            distance: 30.0,
            latitude: 59.1200,
            longitude: 17.9800
        )
    ]

    return FilterSheetView()
        .environment(vm)
        .environment(AuthViewModel(repository: AuthService(), userRepository: UserService()))
}
