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

    var errorMessage: String? = nil

    var searchRadius: Double = 5.0
    var savedUserIDs: Set<String> = []
    var savedUsers: [User] = []
    
    var connectedUserIDs: Set<String> = []


    private let meetRepository: MeetRepository
    private let locationViewModel: LocationViewModel
    private let chatRepository: ChatRepository

    init(
        meetRepository: MeetRepository = MeetService(),
        locationViewModel: LocationViewModel,
        chatRepository: ChatRepository = ChatService()
    ) {
        self.meetRepository = meetRepository
        self.locationViewModel = locationViewModel
        self.chatRepository = chatRepository
    }

    func loadWithLocation() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        do {
            let coordinate = try await locationViewModel.startLocating()
            /// Convert CLLocation to GeoPoint — the repository layer speaks GeoPoint, not CLLocation
            let geoPoint = GeoPoint(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            /// Persist the user's current location to Firestore so others can find them/
            try await meetRepository.updateLocation(geoPoint, userID: userID)
            /// Now we have a location, fetch users nearby
            await loadNearbyUsers()

        } catch LocationError.permissionDenied {
            // locationViewModel already set locationStatus = .denied; MeetView shows the settings message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadNearbyUsers() async {
        guard let currentLocation = locationViewModel.currentUserLocation else {
            return
        }
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
            let partnerIDs = try await chatRepository.fetchConnectedUserIDs(for: Auth.auth().currentUser?.uid ?? "")

            connectedUserIDs = partnerIDs

            allNearbyUsers = allNearbyUsers.filter { !partnerIDs.contains($0.id) }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadSavedProfiles() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        do {
            let users = try await meetRepository.fetchSavedProfiles(for: userID)
            savedUsers = users
            savedUserIDs = Set(users.map { $0.id })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSave(targetID: String) async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        do {
            if savedUserIDs.contains(targetID) {
                try await meetRepository.unsaveProfile(targetID, by: userID)
                savedUserIDs.remove(targetID)
            } else {
                try await meetRepository.saveProfile(targetID, by: userID)
                savedUserIDs.insert(targetID)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
