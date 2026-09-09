#if DEBUG
import PadelCore

/// Sample `MatchEngine` states for `#Preview`s, built by replaying `PointEvent`s through
/// `MatchEngine.score(_:)` — never by hand-constructing `MatchState` (decisions.md #1).
public enum PreviewFixtures {
    /// 40-40 under Star Point, first deuce (not sudden death yet).
    public static var starPointDeuce: MatchEngine {
        var engine = MatchEngine(rules: MatchRules(format: .sets(bestOf: 3), deuceRule: .starPointDefault))
        for _ in 0..<3 { engine.score(.a) }
        for _ in 0..<3 { engine.score(.b) }
        return engine
    }

    /// Finished best-of-3, straight sets, A wins love-love.
    public static var finishedBestOfThree: MatchEngine {
        var engine = MatchEngine(rules: .standardSets)
        for _ in 0..<48 { engine.score(.a) }
        return engine
    }

    /// A Mix round mid-play, a couple of games in.
    public static var midRoundMix: MatchEngine {
        var engine = MatchEngine(rules: .standardMix)
        for _ in 0..<4 { engine.score(.a) }
        engine.score(.b)
        engine.score(.b)
        return engine
    }

    /// A Mix round manually ended with A ahead on games.
    public static var endedMixRoundWonByA: MatchEngine {
        var engine = MatchEngine(rules: .standardMix)
        for _ in 0..<4 { engine.score(.a) } // A wins a game, B wins none
        engine.endManually()
        return engine
    }

    /// A Mix round manually ended in a draw.
    public static var drawnMixRound: MatchEngine {
        var engine = MatchEngine(rules: .standardMix)
        for _ in 0..<4 { engine.score(.a) }
        for _ in 0..<4 { engine.score(.b) }
        engine.endManually()
        return engine
    }

    public static let teamLabels = TeamLabels(a: "Luís & Rui", b: "Tiago & André")
    public static let mixTeamLabels = TeamLabels.mix

    public static let workoutMetrics = WorkoutMetrics(
        heartRate: 138, averageHeartRate: 142, maxHeartRate: 168, activeCalories: 286, elapsed: 32 * 60 + 14
    )
}
#endif
