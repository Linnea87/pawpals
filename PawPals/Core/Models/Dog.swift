import Foundation

struct Dog: Identifiable {
    
    let id: String
    var name: String
    var breed: String
    var size: DogSize
    var ownerId: String
}
