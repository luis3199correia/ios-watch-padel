import Foundation

/// Turns raw scores into the strings players actually expect to see ("40", "AD", "7-6(5)").
/// The only place in `PadelCore` aware of point-label presentation.
public enum ScoreFormatter {
    private static let pointLabels = ["0", "15", "30", "40"]

    /// Label for one team's current game score, e.g. "40", "AD", or a tie-break point count.
    public static func gameScoreLabel(for team: Team, in game: GameScore) -> String {
        if game.isTieBreak { return "\(game.rawScore(for: team))" }

        let mine = game.rawScore(for: team)
        let theirs = game.rawScore(for: team.opponent)

        if mine >= 3, theirs >= 3 {
            if mine == theirs { return "40" }
            return mine > theirs ? "AD" : "40"
        }
        return pointLabels[min(mine, 3)]
    }

    /// Comma-separated summary of completed sets, e.g. "6-4, 7-6(5)". Filters by `endedAt`
    /// rather than `winner` so a drawn mix round (which has no winner) still shows up.
    public static func setScoreSummary(_ sets: [SetScore]) -> String {
        sets
            .filter { $0.endedAt != nil }
            .map { set in
                if let tieBreak = set.tieBreak {
                    let loserPoints = min(tieBreak.pointsA, tieBreak.pointsB)
                    return "\(set.gamesA)-\(set.gamesB)(\(loserPoints))"
                }
                return "\(set.gamesA)-\(set.gamesB)"
            }
            .joined(separator: ", ")
    }
}
