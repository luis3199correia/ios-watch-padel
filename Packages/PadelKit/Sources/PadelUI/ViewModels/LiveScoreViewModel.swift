import Foundation
import Observation
import PadelCore

/// Wraps a `MatchEngine` for the live-scoring watch screens. Derived flags like `isGoldenPointNow`
/// run reducer simulations, so they're read once here on mutation rather than recomputed from
/// a view `body` on every redraw.
@Observable
public final class LiveScoreViewModel {
    public private(set) var engine: MatchEngine
    public var teamLabels: TeamLabels

    public init(engine: MatchEngine, teamLabels: TeamLabels) {
        self.engine = engine
        self.teamLabels = teamLabels
    }

    // MARK: - Score display

    public func pointsLabel(for team: Team) -> String {
        ScoreFormatter.gameScoreLabel(for: team, in: engine.state.currentGame)
    }

    public var setsWonA: Int { engine.state.setsWonA }
    public var setsWonB: Int { engine.state.setsWonB }
    public var isTieBreak: Bool { engine.state.currentGame.isTieBreak }

    /// Games in the current (last, possibly in-progress) set, e.g. "4-3".
    public var currentSetGamesLabel: String {
        guard let set = engine.state.sets.last else { return "0-0" }
        return "\(set.gamesA)-\(set.gamesB)"
    }

    /// Non-nil exactly when the next point, by either team, would end the game outright —
    /// the badge text names which sudden-death rule is in effect.
    public var deuceBadge: String? {
        guard engine.isGoldenPointNow else { return nil }
        let text = MatchLabels.suddenDeathBadge(for: engine.rules.deuceRule)
        return text.isEmpty ? nil : text
    }

    public var isMatchPoint: Bool { engine.isMatchPoint }
    public var isFinished: Bool { engine.isFinished }
    public var canUndo: Bool { engine.canUndo }

    /// "40 Tiago&André" — what the next undo would revert. Reflects the *current* game score,
    /// so it's only accurate mid-game; right after a game/set win the current game has already
    /// reset to 0-0, which is an accepted limitation of this decorative label (not used for any
    /// scoring decision).
    public var lastPointDescription: String? {
        guard let lastTeam = engine.events.last?.team else { return nil }
        return "\(pointsLabel(for: lastTeam)) \(teamLabels.label(for: lastTeam))"
    }

    // MARK: - Mutations

    @discardableResult
    public func score(_ team: Team) -> ScoringOutcome {
        let outcome = engine.score(team)
        if !outcome.wasRejected { PadelHaptics.tick() }
        return outcome
    }

    public func undo() {
        engine.undoLastPoint()
    }

    /// Ends the current Mix round now, based on games won so far. No-op for every other format
    /// (`MatchEngine.endManually` already guards this) — see decisions.md 8b.
    public func endRound() {
        engine.endManually()
    }
}
