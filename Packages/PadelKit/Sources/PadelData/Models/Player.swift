import Foundation
import SwiftData

@Model
public final class Player {
    public var id: UUID = UUID()
    public var name: String = ""
    public var isMe: Bool = false
    public var createdAt: Date = Date.distantPast

    /// Deleting a `Player` nullifies this, not the `MatchParticipant` rows themselves — history
    /// stays readable (the participant's `displayName` survives) even after the player is gone.
    @Relationship(deleteRule: .nullify, inverse: \MatchParticipant.player)
    public var participations: [MatchParticipant] = []

    public init(id: UUID = UUID(), name: String, isMe: Bool = false, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.isMe = isMe
        self.createdAt = createdAt
    }
}

extension Player: UUIDIdentifiedModel {
    public static func idPredicate(_ id: UUID) -> Predicate<Player> {
        #Predicate<Player> { $0.id == id }
    }
}
