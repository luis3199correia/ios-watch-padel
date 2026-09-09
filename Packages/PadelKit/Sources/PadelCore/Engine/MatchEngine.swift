import Foundation

/// Stateful, mutable wrapper around `ScoringReducer` for callers (view models) that just want
/// to say "score a point for team A" / "undo" without manually managing the event log.
public struct MatchEngine: Sendable {
    public let rules: MatchRules
    public private(set) var events: [PointEvent]
    public private(set) var state: MatchState

    /// Set when `endManually()` has finalized the match without a corresponding `PointEvent`
    /// being appended to `events`. Tracked separately so `undoLastPoint()` can undo the manual
    /// end itself first — keeping event-log replay as the source of truth for every point,
    /// while still making the one out-of-band action undoable instead of silently discarding it.
    private var manualEndAt: Date?

    public init(rules: MatchRules, events: [PointEvent] = [], startedAt: Date? = nil) {
        self.rules = rules
        self.events = events.sorted { $0.sequence < $1.sequence }
        self.state = ScoringReducer.replay(self.events, rules: rules, startedAt: startedAt)
        self.manualEndAt = nil
    }

    @discardableResult
    public mutating func score(_ team: Team, at date: Date = .now) -> ScoringOutcome {
        let event = PointEvent(team: team, timestamp: date, sequence: events.count)
        let outcome = ScoringReducer.apply(event, to: state)
        if !outcome.wasRejected {
            events.append(event)
            state = outcome.state
        }
        return outcome
    }

    /// Undoes the last action. If the match was finished by `endManually()`, the first call
    /// undoes just that (reverting to the in-progress state right before it was ended);
    /// otherwise it removes the last point and replays the remaining log. No-op if there is
    /// nothing to undo.
    @discardableResult
    public mutating func undoLastPoint() -> MatchState {
        if manualEndAt != nil {
            manualEndAt = nil
            state = ScoringReducer.replay(events, rules: rules, startedAt: state.startedAt)
            return state
        }
        guard !events.isEmpty else { return state }
        events.removeLast()
        state = ScoringReducer.replay(events, rules: rules, startedAt: state.startedAt)
        return state
    }

    /// Ends the match right now based on games won so far, regardless of score. Only valid for
    /// `.mix` rounds, which have no target and are ended manually (e.g. when the round's time
    /// is up) — a no-op for every other format, or if the match has already finished.
    /// Whichever team has won more games in the current set wins; a tie (including 0-0) is a draw.
    @discardableResult
    public mutating func endManually(at date: Date = .now) -> MatchState {
        guard rules.format == .mix, !state.isFinished, var currentSet = state.sets.last else { return state }

        let outcome: MatchOutcome
        if currentSet.gamesA == currentSet.gamesB {
            outcome = .draw
        } else {
            let winner: Team = currentSet.gamesA > currentSet.gamesB ? .a : .b
            outcome = .win(winner)
            currentSet.winner = winner
        }
        currentSet.endedAt = date

        var newState = state
        newState.sets[newState.sets.count - 1] = currentSet
        newState.phase = .finished(outcome: outcome, at: date)
        state = newState
        manualEndAt = date
        return state
    }

    public var canUndo: Bool { manualEndAt != nil || !events.isEmpty }
    public var isFinished: Bool { state.isFinished }

    /// `true` when the very next point, regardless of which team scores it, would end the
    /// current game (i.e. the deuce rule's sudden-death condition is active right now).
    public var isGoldenPointNow: Bool {
        Team.allCases.allSatisfy { simulate(scoringFor: $0).didWinGame == $0 }
    }

    /// `true` when at least one team is one point away from winning the current set.
    public var isSetPoint: Bool {
        Team.allCases.contains { simulate(scoringFor: $0).didWinSet != nil }
    }

    /// `true` when at least one team is one point away from winning the match.
    public var isMatchPoint: Bool {
        Team.allCases.contains { simulate(scoringFor: $0).didWinMatch != nil }
    }

    private func simulate(scoringFor team: Team) -> ScoringOutcome {
        ScoringReducer.apply(PointEvent(team: team, sequence: events.count), to: state)
    }
}
