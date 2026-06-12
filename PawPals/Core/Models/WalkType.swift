import Foundation

enum WalkType: String, CaseIterable, Codable, Identifiable {
    case morning = "Morning walk"
    case evening = "Evening walk"
    case city = "City walk"
    case forest = "Forest walk"
    case long = "Long walk"
    
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning: String(localized: "walkType.morning")
        case .evening: String(localized: "walkType.evening")
        case .city: String(localized: "walkType.city")
        case .forest: String(localized: "walkType.forest")
        case .long: String(localized: "walkType.long")
        }
    }
}
