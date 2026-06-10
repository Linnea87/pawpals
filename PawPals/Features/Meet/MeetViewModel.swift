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
    var savedUserIds: Set<String> = []
    var savedUsers: [User] = []

    private let meetRepository: MeetRepository
    private let locationService: LocationService

    init(
        meetRepository: MeetRepository = MeetService(),
        locationService: LocationService
    ) {
        self.meetRepository = meetRepository
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
            try await meetRepository.updateLocation(geoPoint, userId: userID)
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
            allNearbyUsers = try await meetRepository.fetchNearbyUsers(
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
            let users = try await meetRepository.fetchSavedProfiles(for: userId)
            savedUsers = users
            savedUserIds = Set(users.map { $0.id })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSave(targetID: String) async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        do {
            if savedUserIds.contains(targetId) {
                try await meetRepository.unsaveProfile(targetId, by: userId)
                savedUserIds.remove(targetId)
            } else {
                try await meetRepository.saveProfile(targetId, by: userId)
                savedUserIds.insert(targetId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
