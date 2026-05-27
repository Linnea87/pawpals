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
                let userWalkTypes = Set(user.preferences.walkTypes.map { $0.rawValue })
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

