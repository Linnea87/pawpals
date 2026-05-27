import Foundation

@Observable
final class MeetViewModel {
    var selectedUser: User?
    var allNearbyUsers: [User] = []
    var filteredUsers: [User] = []
    var selectedFilters: WalkType? = nil
    var activeFilters: Set<String> = []
    var isLoading = false
    var errorMessage: String? = nil
    
    
    func loadNearbyUsers() async {
        isLoading = true
        errorMessage = nil
        allNearbyUsers = [.mock] // Replace with real firebase later
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
    
    private func applyFilters() {
        guard !activeFilters.isEmpty else {
            filteredUsers = allNearbyUsers
            return
        }
        filteredUsers = allNearbyUsers.filter { user in
            let userWalkTypes = Set(user.preferences.walkTypes.map { $0.rawValue })
            return !activeFilters.isDisjoint(with: userWalkTypes)
        }
    }
}
