import Foundation

struct Conversation: Identifiable, Codable {
    var id: String
    var participants: [String]
    var lastMessage: Message?
    var lasMessagesTimestamp: Date
}
