import Foundation

struct FilterPreferences {
    var searchRadius: Double
    var activeFilters: Set<String>
    var activeSizeFilters: Set<String>
}

protocol FilterRepository {
    func saveFilterPreferences(_ prefs: FilterPreferences, userId: String) async throws
    func fetchFilterPreferences(userId: String) async throws -> FilterPreferences
}
