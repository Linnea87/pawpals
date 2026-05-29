import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import Foundation

@Observable
final class MeetViewModel {
    var selectedUser: User?
    var allNearbyUsers: [User] = []
    var filteredUsers: [User] = []
    var activeFilters: Set<String> = []
    var activeSizeFilters: Set<String> = []
    var isLoading = false
    var isLocating = false
    var errorMessage: String? = nil
    var locationStatus: CLAuthorizationStatus = .notDetermined
    var currentUserLocation: CLLocationCoordinate2D?

    private let userRepository: UserRepository
    private let locationService: LocationService

    init(
        userRepository: UserRepository = UserService(),
        locationService: LocationService
    ) {
        self.userRepository = userRepository
        self.locationService = locationService
    }

    func loadWithLocation() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        isLocating = true
        defer { isLocating = false }

        do {
            let location = try await locationService.requestLocationOnce()
            currentUserLocation = location.coordinate
            locationStatus = .authorizedWhenInUse

            let geoPoint = GeoPoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            try await userRepository.updateLocation(geoPoint, userId: userID)
            await loadNearbyUsers()

        } catch LocationError.permissionDenied {
            locationStatus = .denied
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadNearbyUsers() async {
        isLoading = true
        errorMessage = nil
        allNearbyUsers = [.mock]  // Replace with real firebase later
        if let currentLocation = currentUserLocation {
            allNearbyUsers = allNearbyUsers.map { user in
                var updated = user
                if let lat = user.latitude, let lon = user.longitude {
                    let userLocation = CLLocation(latitude: lat, longitude: lon)
                    let current = CLLocation(
                        latitude: currentLocation.latitude,
                        longitude: currentLocation.longitude
                    )
                    let distanceKm = current.distance(from: userLocation) / 1000
                    updated.distance = (distanceKm * 10).rounded() / 10
                }
                return updated
            }
        }
        applyFilters()
        isLoading = false
    }

    func toggleFilter(_ filter: String) {
        if activeFilters.contains(filter) {
            activeFilters.remove(filter)
        } else {
            activeFilters.insert(filter)
        }
        applyFilters()
    }

    func clearFilters() {
        activeFilters.removeAll()
        applyFilters()
    }

    func toggleSizeFilter(_ size: String) {
        if activeSizeFilters.contains(size) {
            activeSizeFilters.remove(size)
        } else {
            activeSizeFilters.insert(size)
        }
        applyFilters()
    }

    func clearSizeFilters() {
        activeSizeFilters.removeAll()
        applyFilters()
    }

    private func applyFilters() {
        var result = allNearbyUsers

        if !activeFilters.isEmpty {
            result = result.filter { user in
                let userWalkTypes = Set(
                    user.preferences.walkTypes.map { $0.rawValue }
                )
                return !activeFilters.isDisjoint(with: userWalkTypes)
            }
        }

        if !activeSizeFilters.isEmpty {
            result = result.filter { user in
                guard let size = user.dogs.first?.size else { return false }
                return activeSizeFilters.contains(size.rawValue)
            }
        }

        filteredUsers = result
    }
}
