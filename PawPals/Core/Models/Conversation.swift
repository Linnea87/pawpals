import Foundation

struct Conversation: Identifiable, Codable, Hashable {
    var id: String
    var participantIDs: [String]
    var lastMessage: String
    var lastMessageTimestamp: Date
    var unreadCounts: [String: Int] = [:]
}
