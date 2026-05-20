import Foundation

struct Message: Identifiable, Codable{
    var id: String
    var senderId: String
    var receiverId: String
    var text: String
    var timestamp: Date 
  
}


