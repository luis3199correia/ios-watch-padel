import Foundation
import PadelCore

public struct TimelineDot: Equatable, Sendable {
    public let team: Team
    /// True when this exact point ended a game via sudden death (golden point / star point's
    /// deuce-limit trigger) — never true under `.classicAdvantage`.
    public let isSuddenDeathDecider: Bool
}

/// Turns the raw event log into a per-point timeline for display. Identifies the sudden-death
/// deciding point of each game by matching `PointEvent.id` against `CompletedGame.id` — the two
/// are the same id for a game-winning event (see `ScoringReducer.apply`, decisions.md #1's
/// correction), so this needs no fragile timestamp comparison.
public enum PointTimelineBuilder {
    public static func build(events: [PointEvent], state: MatchState) -> [TimelineDot] {
        let suddenDeathDeciderIDs = Set(
            state.sets
                .flatMap { $0.completedGames }
                .filter { $0.decidedBySuddenDeath }
                .map { $0.id }
        )
        return events.map { event in
            TimelineDot(team: event.team, isSuddenDeathDecider: suddenDeathDeciderIDs.contains(event.id))
        }
    }
}
