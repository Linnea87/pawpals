import Foundation

struct User: Identifiable {
    
    let id: String
    var displayName: String
    var photoURL: String?
    var city: String
    var bio: String
    var dog: Dog?
}
