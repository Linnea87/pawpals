import CoreLocation
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

    func loadWithLocation(currentUserID: String) async {
        guard !currentUserID.isEmpty else { return }

        do {
            let coordinate = try await locationViewModel.startLocating(
                userID: currentUserID
            )

            try await meetRepository.updateLocation(
                coordinate,
                userID: currentUserID
            )

            await loadNearbyUsers(currentUserID: currentUserID)

        } catch LocationError.permissionDenied {
            /// locationViewModel already set locationStatus = .denied
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadNearbyUsers(currentUserID: String) async {
        guard let currentLocation = locationViewModel.currentUserLocation else {
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {

            allNearbyUsers = try await meetRepository.fetchNearbyUsers(
                location: currentLocation,
                radius: searchRadius,
                excludingUserID: currentUserID
            )
            let partnerIDs = try await chatRepository.fetchConnectedUserIDs(
                for: currentUserID
            )

            connectedUserIDs = partnerIDs

            allNearbyUsers = allNearbyUsers.filter {
                !partnerIDs.contains($0.id)
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadSavedProfiles(currentUserID: String) async {
        guard !currentUserID.isEmpty else { return }
        do {
            let users = try await meetRepository.fetchSavedProfiles(
                for: currentUserID
            )
            savedUsers = users
            savedUserIDs = Set(users.map { $0.id })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSave(targetID: String, currentUserID: String) async {
        guard !currentUserID.isEmpty else { return }
        do {
            if savedUserIDs.contains(targetID) {
                try await meetRepository.unsaveProfile(
                    targetID,
                    by: currentUserID
                )
                savedUserIDs.remove(targetID)
            } else {
                try await meetRepository.saveProfile(
                    targetID,
                    by: currentUserID
                )
                savedUserIDs.insert(targetID)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
