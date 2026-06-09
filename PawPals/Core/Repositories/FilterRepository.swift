import Foundation

struct FilterPreferences {
    var searchRadius: Double
    var activeFilters: Set<String>
    var activeSizeFilters: Set<String>
}

protocol FilterRepository {
    func saveFilterPreferences(_ prefs: FilterPreferences, userID: String) async throws
    func fetchFilterPreferences(userID: String) async throws -> FilterPreferences
}
