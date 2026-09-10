import Foundation
import SwiftData
import PadelCore

/// One side's participant slot when scheduling a standalone match. Not `Sendable` — it can hold
/// a `Player`, a SwiftData model confined to its `ModelContext`, so this only ever crosses
/// synchronously within a single call to `scheduleMatch(...)`, never across a concurrency
/// boundary.
public struct ParticipantSlot {
    public let team: Team
    public let displayName: String
    public let position: Int
    public let player: Player?

    public init(team: Team, displayName: String, position: Int, player: Player? = nil) {
        self.team = team
        self.displayName = displayName
        self.position = position
        self.player = player
    }
}

/// Repository for standalone `Match`es (Mix rounds go through `SessionRepository`, which calls
/// back into `finish(_:engine:at:in:)` here for the per-round write).
public enum MatchRepository {

    /// Creates, inserts, and returns a new scheduled standalone match with its 4 participants.
    @discardableResult
    public static func scheduleMatch(
        rules: MatchRules, scheduledAt: Date, location: String,
        participants: [ParticipantSlot], in context: ModelContext
    ) -> Match {
        let match = Match(location: location, rules: rules, scheduledAt: scheduledAt)
        context.insert(match)
        for slot in participants {
            let participant = MatchParticipant(team: slot.team, displayName: slot.displayName, position: slot.position, player: slot.player)
            context.insert(participant)
            participant.match = match
        }
        return match
    }

    public static func start(_ match: Match, at date: Date = .now) {
        guard match.status == .scheduled else { return }
        match.statusRaw = MatchStatus.inProgress.rawValue
        match.startedAt = date
    }

    /// Persists the engine's current event log so an in-progress match survives relaunch —
    /// resuming means `MatchEngine(rules:events:startedAt:)`, i.e. `ScoringReducer.replay`
    /// (decisions.md #1).
    public static func saveProgress(_ match: Match, engine: MatchEngine) {
        match.events = engine.events
    }

    /// Finishes a match: writes the denormalized `MatchSet` rows and the outcome once, from the
    /// engine's final `MatchState` — a finished match is read back afterwards as static data,
    /// never replayed again (decisions.md #8b).
    public static func finish(_ match: Match, engine: MatchEngine, at date: Date = .now, in context: ModelContext) {
        guard case .finished(let outcome, _) = engine.state.phase else { return }
        match.events = engine.events

        for setScore in engine.state.sets {
            let matchSet = MatchSet(
                index: setScore.index,
                gamesA: setScore.gamesA,
                gamesB: setScore.gamesB,
                tieBreakPointsA: setScore.tieBreak?.pointsA,
                tieBreakPointsB: setScore.tieBreak?.pointsB,
                winnerTeamRaw: setScore.winner?.rawValue,
                startedAt: setScore.startedAt,
                endedAt: setScore.endedAt
            )
            context.insert(matchSet)
            matchSet.match = match
        }

        match.outcomeKindRaw = outcome.kindRaw.rawValue
        match.winnerTeamRaw = outcome.winnerRaw
        match.endedAt = date
        match.statusRaw = MatchStatus.finished.rawValue
    }

    /// Scheduled standalone matches (not part of a Mix session), soonest first. Sorted in memory
    /// rather than via a `FetchDescriptor` `SortDescriptor` — `scheduledAt` is optional, and
    /// this app's data volume never makes an in-memory sort worth the extra risk.
    public static func upcoming(in context: ModelContext) throws -> [Match] {
        let statusValue = MatchStatus.scheduled.rawValue
        let descriptor = FetchDescriptor<Match>(
            predicate: #Predicate<Match> { $0.statusRaw == statusValue && $0.session == nil }
        )
        return try context.fetch(descriptor).sorted {
            ($0.scheduledAt ?? .distantFuture) < ($1.scheduledAt ?? .distantFuture)
        }
    }

    /// Finished standalone matches (not part of a Mix session), most recent first. See
    /// `upcoming(in:)` for why this sorts in memory instead of via `SortDescriptor`.
    public static func history(in context: ModelContext) throws -> [Match] {
        let statusValue = MatchStatus.finished.rawValue
        let descriptor = FetchDescriptor<Match>(
            predicate: #Predicate<Match> { $0.statusRaw == statusValue && $0.session == nil }
        )
        return try context.fetch(descriptor).sorted {
            ($0.endedAt ?? .distantPast) > ($1.endedAt ?? .distantPast)
        }
    }
}
