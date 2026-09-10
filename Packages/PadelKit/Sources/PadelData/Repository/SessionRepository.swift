import Foundation
import SwiftData
import PadelCore

/// Repository for Mix `Session`s (decisions.md #8b): "my team" is always `Team.a`, created once
/// and shared across every round; each round's opponents are always anonymous `Team.b`
/// participants, created fresh per round and never backed by a `Player`.
public enum SessionRepository {

    /// Creates, inserts, and returns a new scheduled session with its shared "my team" lineup.
    /// `lineup` is 1 or 2 real players (the device owner, optionally + a named partner), placed
    /// at positions 0 and 1 on `Team.a`.
    @discardableResult
    public static func start(
        rules: MatchRules, scheduledAt: Date, location: String,
        targetDuration: TimeInterval, targetRoundDuration: TimeInterval?,
        lineup: [Player], in context: ModelContext
    ) -> Session {
        let session = Session(
            location: location, targetDuration: targetDuration, targetRoundDuration: targetRoundDuration,
            rules: rules, scheduledAt: scheduledAt
        )
        context.insert(session)
        for (position, player) in lineup.enumerated() {
            let participant = MatchParticipant(team: .a, displayName: player.name, position: position, player: player)
            context.insert(participant)
            participant.session = session
        }
        return session
    }

    /// Starts the next round: an in-progress `.mix` `Match` against two fresh, anonymous
    /// `Team.b` opponents.
    @discardableResult
    public static func addRound(to session: Session, at date: Date = .now, in context: ModelContext) -> Match {
        let round = Match(roundIndex: session.rounds.count, rules: session.rules)
        context.insert(round)
        round.session = session
        round.statusRaw = MatchStatus.inProgress.rawValue
        round.startedAt = date

        let opponent1 = MatchParticipant(team: .b, displayName: "Adversário 1", position: 0)
        let opponent2 = MatchParticipant(team: .b, displayName: "Adversário 2", position: 1)
        context.insert(opponent1)
        context.insert(opponent2)
        opponent1.match = round
        opponent2.match = round
        return round
    }

    /// Finishes one round — delegates to `MatchRepository.finish`, which is format-agnostic.
    public static func finishRound(_ round: Match, engine: MatchEngine, at date: Date = .now, in context: ModelContext) {
        MatchRepository.finish(round, engine: engine, at: date, in: context)
    }

    public static func finish(_ session: Session, at date: Date = .now) {
        session.statusRaw = SessionStatus.finished.rawValue
        session.endedAt = date
    }

    /// Finished sessions, most recent first — each renders as one aggregated history entry
    /// (decisions.md #8b), never one entry per round. Sorted in memory; see
    /// `MatchRepository.upcoming(in:)` for why.
    public static func history(in context: ModelContext) throws -> [Session] {
        let statusValue = SessionStatus.finished.rawValue
        let descriptor = FetchDescriptor<Session>(predicate: #Predicate<Session> { $0.statusRaw == statusValue })
        return try context.fetch(descriptor).sorted {
            ($0.endedAt ?? .distantPast) > ($1.endedAt ?? .distantPast)
        }
    }
}
