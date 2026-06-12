import FirebaseFirestore
import Foundation

final class FilterService: FilterRepository {
    private let db = Firestore.firestore()

    func saveFilterPreferences(_ prefs: FilterPreferences, userID: String) async throws {
        let data: [String: Any] = [
            "searchRadius": prefs.searchRadius,
            "activeFilters": Array(prefs.activeFilters),
            "activeSizeFilters": Array(prefs.activeSizeFilters)
        ]
        try await db.collection("users").document(userID)
            .collection("preferences").document("filters")
            .setData(data)
    }

    func fetchFilterPreferences(userID: String) async throws -> FilterPreferences {
        let snapshot = try await db.collection("users").document(userID)
            .collection("preferences").document("filters")
            .getDocument()

        let data = snapshot.data() ?? [:]
        return FilterPreferences(
            searchRadius: data["searchRadius"] as? Double ?? 5.0,
            activeFilters: Set(data["activeFilters"] as? [String] ?? []),
            activeSizeFilters: Set(data["activeSizeFilters"] as? [String] ?? [])
        )
    }
}
