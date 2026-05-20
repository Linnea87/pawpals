import Foundation

struct Dog: Identifiable, Codable {
    var id: String
    var name: String
    var breed: String
    var age: Int
    var size: DogSize
    
  
}
