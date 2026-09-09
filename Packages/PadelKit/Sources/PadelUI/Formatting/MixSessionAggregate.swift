import PadelCore

/// Aggregate record across a Mix session's rounds — wins/draws/losses (from team A's, "my
/// team's", perspective — decisions.md 8b) and total games won by each side.
public struct MixSessionAggregate: Equatable, Sendable {
    public let wins: Int
    public let draws: Int
    public let losses: Int
    public let totalGamesA: Int
    public let totalGamesB: Int

    public var totalGamesLabel: String { "\(totalGamesA)-\(totalGamesB)" }
}

public enum MixSessionAggregator {
    /// `rounds` are finished `MatchState`s (one per completed round in the session).
    public static func aggregate(_ rounds: [MatchState]) -> MixSessionAggregate {
        var wins = 0, draws = 0, losses = 0
        var gamesA = 0, gamesB = 0

        for round in rounds {
            if round.phase.winner == .a { wins += 1 }
            else if round.phase.winner == .b { losses += 1 }
            else if round.phase.isDraw { draws += 1 }

            if let set = round.sets.last {
                gamesA += set.games(for: .a)
                gamesB += set.games(for: .b)
            }
        }

        return MixSessionAggregate(wins: wins, draws: draws, losses: losses, totalGamesA: gamesA, totalGamesB: gamesB)
    }
}
