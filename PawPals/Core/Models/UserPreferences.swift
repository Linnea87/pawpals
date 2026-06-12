import Foundation

struct UserPreferences: Codable {
    var walkTypes: [WalkType]
    var dogSize: DogSize
    var searchRadius: Double
}
