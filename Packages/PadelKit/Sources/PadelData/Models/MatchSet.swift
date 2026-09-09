import Foundation
import SwiftData

/// Denormalized final `SetScore`, written once when a `Match` finishes. Exists so `HistoryScreen`
/// can render a set-score pill per row (`ScoreFormatter.setScoreSummary`-shaped) from a flat
/// fetch, instead of JSON-decoding and replaying the whole event log for every row in the list.
@Model
public final class MatchSet {
    public var id: UUID = UUID()
    public var index: Int = 0
    public var gamesA: Int = 0
    public var gamesB: Int = 0
    public var tieBreakPointsA: Int?
    public var tieBreakPointsB: Int?
    /// `Team.rawValue`, `nil` for a drawn Mix round.
    public var winnerTeamRaw: String?
    public var startedAt: Date?
    public var endedAt: Date?

    public var match: Match?

    public init(
        id: UUID = UUID(), index: Int, gamesA: Int, gamesB: Int,
        tieBreakPointsA: Int? = nil, tieBreakPointsB: Int? = nil,
        winnerTeamRaw: String? = nil, startedAt: Date? = nil, endedAt: Date? = nil
    ) {
        self.id = id
        self.index = index
        self.gamesA = gamesA
        self.gamesB = gamesB
        self.tieBreakPointsA = tieBreakPointsA
        self.tieBreakPointsB = tieBreakPointsB
        self.winnerTeamRaw = winnerTeamRaw
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}

extension MatchSet: UUIDIdentifiedModel {
    public static func idPredicate(_ id: UUID) -> Predicate<MatchSet> {
        #Predicate<MatchSet> { $0.id == id }
    }
}
