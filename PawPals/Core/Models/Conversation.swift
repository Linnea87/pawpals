import Foundation

struct Conversation: Identifiable, Codable {
    var id: String
    var participantIDs: [String]
    var lastMessage: String
    var lastMessageTimestamp: Date
    var unreadCount: Int = 0 // // ← default 0 so existing code doesn't break code coming in PP-023 
}
