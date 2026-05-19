import Foundation

struct Conversation: Identifiable, Codable {
    var id: String
    var participantIDs: [String]
    var lastMessage: String
    var lastMessageTimestamp: Date
}
