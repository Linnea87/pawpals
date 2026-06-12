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

    func loadPreferences(userID: String) async {
        guard
            let prefs = try? await filterRepository.fetchFilterPreferences(
                userID: userID
            )
        else { return }
        searchRadius = prefs.searchRadius
        activeFilters = prefs.activeFilters
        activeSizeFilters = prefs.activeSizeFilters
    }

    func savePreferences(userID: String) {
        let prefs = FilterPreferences(
            searchRadius: searchRadius,
            activeFilters: activeFilters,
            activeSizeFilters: activeSizeFilters
        )
        Task {
            try? await filterRepository.saveFilterPreferences(
                prefs,
                userID: userID
            )
        }
    }

    func toggleFilter(_ filter: String, userID: String) {
        if activeFilters.contains(filter) {
            activeFilters.remove(filter)
        } else {
            activeFilters.insert(filter)
        }
        savePreferences(userID: userID)
    }

    func clearFilters(userID: String) {
        activeFilters.removeAll()
        savePreferences(userID: userID)
    }

    func toggleSizeFilter(_ size: String, userID: String) {
        if activeSizeFilters.contains(size) {
            activeSizeFilters.remove(size)
        } else {
            activeSizeFilters.insert(size)
        }
        savePreferences(userID: userID)
    }

    func clearSizeFilters(userID: String) {
        activeSizeFilters.removeAll()
        savePreferences(userID: userID)
    }

    func setRadius(_ km: Double) {
        searchRadius = km
    }

    func commitRadius(userID: String) {
        savePreferences(userID: userID)
    }

    func applyFilters(to users: [User]) -> [User] {
        var result = users

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
                activeSizeFilters.contains(user.preferences.dogSize.rawValue)
            }
        }

        return result
    }
}
