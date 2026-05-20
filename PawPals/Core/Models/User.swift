import Foundation

struct User: Identifiable, Codable {
    var id: String
    var name: String
    var photoURL: String?
    var bio: String
    var city: String
    var dogs: [Dog]
    var preferences: UserPreferences
    var distance: Double?
}
