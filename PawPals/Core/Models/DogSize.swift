import Foundation

enum DogSize: String, CaseIterable, Codable {
    
    case small
    case medium
    case large

    var displayName: String {
        switch self {
        case .small: String(localized: "dogSize.small")
        case .medium: String(localized: "dogSize.medium")
        case .large: String(localized: "dogSize.large")
        }
    }
}
