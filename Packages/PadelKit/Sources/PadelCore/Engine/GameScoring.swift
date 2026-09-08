import Foundation

/// Result of awarding a single point within a game (regular or tie-break).
enum GameOutcome: Equatable, Sendable {
    case ongoing(GameScore)
    case won(by: Team, final: GameScore, decidedBySuddenDeath: Bool)
}

/// Scoring for a regular (non-tie-break) game: 0/15/30/40, with deuce resolved according to
/// the match's `DeuceRule`.
enum GameScoring {
    static func awardPoint(to team: Team, in game: GameScore, deuceRule: DeuceRule) -> GameOutcome {
        precondition(!game.isTieBreak, "Use TieBreakScoring for tie-break games")

        let opponent = team.opponent
        let scoreForTeam = game.rawScore(for: team)
        let scoreForOpponent = game.rawScore(for: opponent)

        // If we're currently tied at deuce (40-40 or higher) and this deuce occurrence has
        // reached the rule's sudden-death threshold, the next point decides the game outright,
        // with no advantage stage.
        if scoreForTeam == scoreForOpponent, scoreForTeam >= 3, isSuddenDeath(deuceCount: game.deuceCount, rule: deuceRule) {
            let finalScore = applyPoint(team, to: game)
            return .won(by: team, final: finalScore, decidedBySuddenDeath: true)
        }

        return resolve(applyPoint(team, to: game))
    }

    private static func applyPoint(_ team: Team, to game: GameScore) -> GameScore {
        var updated = game
        if team == .a { updated.rawA += 1 } else { updated.rawB += 1 }
        return updated
    }

    private static func resolve(_ game: GameScore) -> GameOutcome {
        let a = game.rawA, b = game.rawB

        if a >= 4, a - b >= 2 { return .won(by: .a, final: game, decidedBySuddenDeath: false) }
        if b >= 4, b - a >= 2 { return .won(by: .b, final: game, decidedBySuddenDeath: false) }

        // Only once both teams have reached 40 (raw score 3) does reaching a tie count as a
        // new "deuce" occurrence.
        if a >= 3, b >= 3, a == b {
            var updated = game
            updated.deuceCount += 1
            return .ongoing(updated)
        }

        return .ongoing(game)
    }

    private static func isSuddenDeath(deuceCount: Int, rule: DeuceRule) -> Bool {
        switch rule {
        case .classicAdvantage: return false
        case .goldenPoint: return deuceCount >= 1
        case .starPoint(let deuceLimit): return deuceCount >= deuceLimit
        }
    }
}

/// Scoring for a tie-break game: first to `targetPoints` with a 2-point margin, no deuce rule.
enum TieBreakScoring {
    static func awardPoint(to team: Team, in game: GameScore, targetPoints: Int) -> GameOutcome {
        precondition(game.isTieBreak, "Use GameScoring for regular games")

        var next = game
        if team == .a { next.rawA += 1 } else { next.rawB += 1 }

        let a = next.rawA, b = next.rawB
        if a >= targetPoints, a - b >= 2 { return .won(by: .a, final: next, decidedBySuddenDeath: false) }
        if b >= targetPoints, b - a >= 2 { return .won(by: .b, final: next, decidedBySuddenDeath: false) }
        return .ongoing(next)
    }
}

/// Serve rotation helpers. In v1 serve is tracked at team level only (alternates every game);
/// individual player rotation within a team is deferred to a later phase.
enum ServeRotation {
    static func nextServer(after currentServer: Team) -> Team { currentServer.opponent }

    /// Which team serves the `pointNumber`-th point of a tie-break (1-based), given who served
    /// the tie-break's opening point. The first point is served by `firstServer`; thereafter
    /// serve alternates every 2 points.
    static func tieBreakServer(pointNumber: Int, firstServer: Team) -> Team {
        precondition(pointNumber >= 1)
        if pointNumber == 1 { return firstServer }
        let block = (pointNumber - 2) / 2
        return block % 2 == 0 ? firstServer.opponent : firstServer
    }
}
