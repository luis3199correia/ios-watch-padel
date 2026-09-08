import Foundation

/// Stateful, mutable wrapper around `ScoringReducer` for callers (view models) that just want
/// to say "score a point for team A" / "undo" without manually managing the event log.
public struct MatchEngine: Sendable {
    public let rules: MatchRules
    public private(set) var events: [PointEvent]
    public private(set) var state: MatchState

    public init(rules: MatchRules, events: [PointEvent] = [], startedAt: Date? = nil) {
        self.rules = rules
        self.events = events.sorted { $0.sequence < $1.sequence }
        self.state = ScoringReducer.replay(self.events, rules: rules, startedAt: startedAt)
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

    /// Removes the last point and replays the remaining log. No-op if there are no points yet.
    @discardableResult
    public mutating func undoLastPoint() -> MatchState {
        guard !events.isEmpty else { return state }
        events.removeLast()
        state = ScoringReducer.replay(events, rules: rules, startedAt: state.startedAt)
        return state
    }

    public var canUndo: Bool { !events.isEmpty }
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
