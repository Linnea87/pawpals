import Foundation

struct Message: Identifiable, Codable{
    var id: String
    var senderID: String
    var receiverID: String
    var text: String
    var timestamp: Date
    var isRead = false
}


