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
    var searchRadius: Double = 5.0
    var savedUserIDs: Set<String> = []

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
            /// Request a single real GPS location using the modern iOS 17 AsyncSequence API
            let location = try await locationService.requestLocationOnce()
            currentUserLocation = location.coordinate
            locationStatus = .authorizedWhenInUse

            /// Convert CLLocation to GeoPoint — the repository layer speaks GeoPoint, not CLLocation
            let geoPoint = GeoPoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            /// Persist the user's current location to Firestore so others can find them/
            try await userRepository.updateLocation(geoPoint, userID: userID)
            /// Now we have a location, fetch users nearby
            await loadNearbyUsers()

        } catch LocationError.permissionDenied {
            /// User denied location access — update status so the View can show the correct UI
            locationStatus = .denied
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadNearbyUsers() async {
        guard let currentLocation = currentUserLocation else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            
            let geoPoint = GeoPoint(
                latitude: currentLocation.latitude,
                longitude: currentLocation.longitude
            )
            allNearbyUsers = try await userRepository.fetchNearbyUsers(
                location: geoPoint,
                radius: searchRadius,
                excludingUserID: Auth.auth().currentUser?.uid ?? ""
            )

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadSavedProfiles() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        do {
            let users = try await userRepository.fetchSavedProfiles(for: userID)
            savedUserIDs = Set(users.map { $0.id })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSave(targetID: String) async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        do {
            if savedUserIDs.contains(targetID) {
                try await userRepository.unsaveProfile(targetID, by: userID)
                savedUserIDs.remove(targetID)
            } else {
                try await userRepository.saveProfile(targetID, by: userID)
                savedUserIDs.insert(targetID)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
