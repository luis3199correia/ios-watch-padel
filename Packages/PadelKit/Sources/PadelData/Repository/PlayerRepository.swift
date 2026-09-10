import Foundation
import SwiftData

/// Repository for `Player` — the only entity a screen creates/updates directly by name (Mix
/// opponents never get a `Player` record, per decisions.md #8b).
public enum PlayerRepository {

    @discardableResult
    public static func upsert(id: UUID = UUID(), name: String, isMe: Bool = false, in context: ModelContext) throws -> Player {
        try context.upsert(Player.self, id: id, make: { Player(id: id, name: name, isMe: isMe) }) { player in
            player.name = name
            player.isMe = isMe
        }
    }

    public static func all(in context: ModelContext) throws -> [Player] {
        try context.fetch(FetchDescriptor<Player>(sortBy: [SortDescriptor(\.name)]))
    }

    /// The single `Player` representing the device's owner, if one has been created yet.
    public static func me(in context: ModelContext) throws -> Player? {
        var descriptor = FetchDescriptor<Player>(predicate: #Predicate<Player> { $0.isMe })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
