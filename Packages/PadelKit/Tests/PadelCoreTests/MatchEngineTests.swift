import Foundation
import Testing
@testable import PadelCore

@Suite("MatchEngine — undo/replay, rejection, and live-state flags")
struct MatchEngineTests {

    @Test("Undo restores the exact previous state, including across a game win")
    func undoAcrossGameWin() {
        var engine = MatchEngine(rules: .standardSets)
        for _ in 0..<3 { engine.score(.a) } // 40-0
        let beforeGameWin = engine.state

        engine.score(.a) // wins the game 4-0
        #expect(engine.state.sets.last?.completedGames.count == 1)

        engine.undoLastPoint()
        #expect(engine.state == beforeGameWin)
    }

    @Test("Undo is a no-op on an empty log")
    func undoOnEmptyLogIsNoOp() {
        var engine = MatchEngine(rules: .standardSets)
        let initial = engine.state
        engine.undoLastPoint()
        #expect(engine.state == initial)
        #expect(engine.canUndo == false)
    }

    @Test("Points scored after the match has finished are rejected and do not change the state")
    func pointsAfterMatchEndAreRejected() {
        var engine = MatchEngine(rules: MatchRules(format: .sets(bestOf: 1), deuceRule: .classicAdvantage))
        for _ in 0..<24 { engine.score(.a) } // wins 6 love games -> set + match won
        #expect(engine.isFinished)
        let finished = engine.state

        let outcome = engine.score(.b)
        #expect(outcome.wasRejected)
        #expect(engine.state == finished)
    }

    @Test("replay(events:) matches incremental application (reducer/engine equivalence)")
    func replayMatchesIncrementalApplication() {
        var engine = MatchEngine(rules: .standardSets)
        let teams: [Team] = [.a, .a, .a, .a, .b, .b, .b, .a, .a]
        for team in teams { engine.score(team) }

        let replayed = ScoringReducer.replay(engine.events, rules: .standardSets)
        #expect(replayed == engine.state)
    }

    @Test("500 random points followed by 500 undos returns to the initial state")
    func randomizedUndoRoundTrip() {
        var generator = SeededGenerator(seed: 42)
        var engine = MatchEngine(rules: .standardSets)
        let initial = engine.state

        for _ in 0..<500 {
            let team: Team = Bool.random(using: &generator) ? .a : .b
            engine.score(team)
        }
        for _ in 0..<500 {
            engine.undoLastPoint()
        }

        #expect(engine.state == initial)
        #expect(engine.events.isEmpty)
    }

    @Test("isGoldenPointNow is true only when BOTH teams scoring would win the game (golden point rule)")
    func isGoldenPointNowReflectsSuddenDeath() {
        var engine = MatchEngine(rules: MatchRules(format: .sets(bestOf: 3), deuceRule: .goldenPoint))
        for _ in 0..<3 { engine.score(.a) }
        for _ in 0..<3 { engine.score(.b) } // 40-40 under golden point
        #expect(engine.isGoldenPointNow)
    }

    @Test("isGoldenPointNow is false during a classic-advantage state (only one team would win)")
    func isGoldenPointNowFalseDuringAdvantage() {
        var engine = MatchEngine(rules: .standardSets) // classicAdvantage
        for _ in 0..<3 { engine.score(.a) }
        for _ in 0..<3 { engine.score(.b) } // 40-40
        engine.score(.a) // advantage A — only A winning the next point ends the game
        #expect(engine.isGoldenPointNow == false)
    }

    @Test("isMatchPoint is true when a team one point from winning the deciding game would win the match")
    func isMatchPointDetection() {
        let rules = MatchRules(format: .sets(bestOf: 1), deuceRule: .classicAdvantage)
        var engine = MatchEngine(rules: rules)
        for _ in 0..<5 {
            for _ in 0..<4 { engine.score(.a) } // A wins 5 games to love
        }
        // A is at 0 points in game 6; scoring 4 in a row would win 6-0 and the (single-set) match.
        for _ in 0..<3 { engine.score(.a) }
        #expect(engine.isMatchPoint)
    }
}

/// Deterministic pseudo-random generator so property-style tests are reproducible.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
