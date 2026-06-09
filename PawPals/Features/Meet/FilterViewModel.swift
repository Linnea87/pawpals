import Foundation

@Observable
final class FilterViewModel {
    var searchRadius: Double = 5.0
    var activeFilters: Set<String> = []
    var activeSizeFilters: Set<String> = []

    private let filterRepository: FilterRepository

    init(filterRepository: FilterRepository = FilterService()) {
        self.filterRepository = filterRepository
    }

    func loadPreferences(userId: String) async {
        guard let prefs = try? await filterRepository.fetchFilterPreferences(userId: userId) else { return }
        searchRadius = prefs.searchRadius
        activeFilters = prefs.activeFilters
        activeSizeFilters = prefs.activeSizeFilters
    }

    func savePreferences(userId: String) {
        let prefs = FilterPreferences(
            searchRadius: searchRadius,
            activeFilters: activeFilters,
            activeSizeFilters: activeSizeFilters
        )
        Task { try? await filterRepository.saveFilterPreferences(prefs, userId: userId) }
    }

    func toggleFilter(_ filter: String, userId: String) {
        if activeFilters.contains(filter) {
            activeFilters.remove(filter)
        } else {
            activeFilters.insert(filter)
        }
        savePreferences(userId: userId)
    }

    func clearFilters(userId: String) {
        activeFilters.removeAll()
        savePreferences(userId: userId)
    }

    func toggleSizeFilter(_ size: String, userId: String) {
        if activeSizeFilters.contains(size) {
            activeSizeFilters.remove(size)
        } else {
            activeSizeFilters.insert(size)
        }
        savePreferences(userId: userId)
    }

    func clearSizeFilters(userId: String) {
        activeSizeFilters.removeAll()
        savePreferences(userId: userId)
    }

    func setRadius(_ km: Double, userId: String) {
        searchRadius = km
        savePreferences(userId: userId)
    }

    func applyFilters(to users: [User]) -> [User] {
        var result = users

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

        return result
    }
}
