import Foundation

/// Result of a regular (non-tie-break) game just being completed within a set.
enum SetOutcome: Equatable, Sendable {
    case ongoing(SetScore)
    case enteredTieBreak(SetScore)
    case won(by: Team, final: SetScore)
}

enum SetScoring {
    /// Evaluates the set after a REGULAR game has just completed (games count already updated).
    /// A tie-break-deciding game is handled directly by the caller (`ScoringReducer`), since a
    /// tie-break always finishes the set outright regardless of the 2-game-margin rule.
    static func evaluateAfterRegularGame(_ set: SetScore, rules: MatchRules) -> SetOutcome {
        let a = set.gamesA, b = set.gamesB

        if a >= rules.gamesToWinSet, a - b >= 2 { return .won(by: .a, final: set) }
        if b >= rules.gamesToWinSet, b - a >= 2 { return .won(by: .b, final: set) }
        if a == rules.tieBreakAtGames, b == rules.tieBreakAtGames { return .enteredTieBreak(set) }
        return .ongoing(set)
    }
}

enum MatchWinnerEvaluator {
    static func winner(in sets: [SetScore], rules: MatchRules) -> Team? {
        let wonA = sets.filter { $0.winner == .a }.count
        let wonB = sets.filter { $0.winner == .b }.count
        if wonA >= rules.setsNeededToWin { return .a }
        if wonB >= rules.setsNeededToWin { return .b }
        return nil
    }
}
