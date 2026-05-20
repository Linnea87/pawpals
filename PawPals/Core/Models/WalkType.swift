import Foundation

enum WalkType: String, CaseIterable, Codable, Identifiable {
    case morning = "Morning walk"
    case evening = "Evening walk"
    case city = "City walk"
    case forest = "Forest walk"
    case long = "Long walk"
    
    var id: String { rawValue }
}
