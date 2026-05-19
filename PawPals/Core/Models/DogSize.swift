import Foundation

enum DogSize: String, CaseIterable, Codable, Identifiable {
    case small = "Small breed"
    case medium = "Medium breed"
    case large = "Big breed"
    
    var id: String { rawValue }
}
