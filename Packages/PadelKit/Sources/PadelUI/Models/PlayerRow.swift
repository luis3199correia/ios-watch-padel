import Foundation

/// A row in the players list. Populated from SwiftData in Fase 2 (decisions.md #9).
public struct PlayerRow: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let initials: String
    public let matchesPlayed: Int
    public let wins: Int
    public let isMe: Bool

    public init(id: UUID = UUID(), name: String, initials: String, matchesPlayed: Int, wins: Int, isMe: Bool = false) {
        self.id = id
        self.name = name
        self.initials = initials
        self.matchesPlayed = matchesPlayed
        self.wins = wins
        self.isMe = isMe
    }
}
