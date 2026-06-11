import CoreLocation
import Foundation

@Observable
final class MeetViewModel {
    var selectedUser: User?
    var allNearbyUsers: [User] = []
    var isLoading = false

    var errorMessage: String? = nil

    var savedUserIDs: Set<String> = []
    var savedUsers: [User] = []

    var connectedUserIDs: Set<String> = []

    private let meetRepository: MeetRepository
    private let locationViewModel: LocationViewModel
    private let chatRepository: ChatRepository
    private var radiusDebounce: Task<Void, Never>?

    init(
        meetRepository: MeetRepository = MeetService(),
        locationViewModel: LocationViewModel,
        chatRepository: ChatRepository = ChatService()
    ) {
        self.meetRepository = meetRepository
        self.locationViewModel = locationViewModel
        self.chatRepository = chatRepository
    }

    func loadWithLocation(currentUserID: String, radius: Double) async {
        guard !currentUserID.isEmpty else { return }

        do {
            let coordinate = try await locationViewModel.startLocating(
                userID: currentUserID
            )

            try await meetRepository.updateLocation(
                coordinate,
                userID: currentUserID
            )

            await loadNearbyUsers(currentUserID: currentUserID, radius: radius)

        } catch LocationError.permissionDenied {
            /// locationViewModel already set locationStatus = .denied
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func radiusChanged(to radius: Double, currentUserID: String) {
        
        radiusDebounce?.cancel()
        
        radiusDebounce = Task {
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled else { return }
            await loadNearbyUsers(currentUserID: currentUserID, radius: radius)
        }
    }
    func loadNearbyUsers(currentUserID: String, radius: Double) async {
        guard let currentLocation = locationViewModel.currentUserLocation else {
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {

            allNearbyUsers = try await meetRepository.fetchNearbyUsers(
                location: currentLocation,
                radius: radius,
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
