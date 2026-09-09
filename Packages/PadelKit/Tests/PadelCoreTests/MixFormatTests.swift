import Foundation
import Testing
@testable import PadelCore

@Suite("Mix format — games without a target, ended manually, possibly a draw")
struct MixFormatTests {

    @Test("Mix never auto-completes, no matter how many games are played")
    func mixNeverAutoCompletes() {
        var engine = MatchEngine(rules: .standardMix)
        for _ in 0..<20 {
            for _ in 0..<4 { engine.score(.a) } // A wins a love game each time
        }
        #expect(engine.isFinished == false)
        #expect(engine.state.sets.count == 1, "Mix plays one continuous round; games never trigger a new set")
        #expect(engine.state.sets[0].gamesA == 20)
        #expect(engine.state.sets[0].tieBreak == nil, "Mix has no tie-break concept")
    }

    @Test("endManually declares the team with more games as winner")
    func endManuallyDeclaresWinner() {
        var engine = MatchEngine(rules: .standardMix)
        for _ in 0..<4 { engine.score(.a) } // A: 1 game
        for _ in 0..<4 { engine.score(.a) } // A: 2 games
        for _ in 0..<4 { engine.score(.b) } // B: 1 game

        engine.endManually()

        #expect(engine.isFinished)
        #expect(engine.state.phase.winner == .a)
        #expect(engine.state.sets[0].gamesA == 2 && engine.state.sets[0].gamesB == 1)
    }

    @Test("endManually with equal games is a draw")
    func endManuallyDraw() {
        var engine = MatchEngine(rules: .standardMix)
        for _ in 0..<4 { engine.score(.a) }
        for _ in 0..<4 { engine.score(.b) }

        engine.endManually()

        #expect(engine.isFinished)
        #expect(engine.state.phase.winner == nil)
        #expect(engine.state.phase.isDraw)
    }

    @Test("endManually with no games played at all is also a draw (0-0)")
    func endManuallyOnFreshRoundIsDraw() {
        var engine = MatchEngine(rules: .standardMix)
        engine.endManually()
        #expect(engine.isFinished)
        #expect(engine.state.phase.isDraw)
    }

    @Test("endManually is a no-op once the round has already finished")
    func endManuallyNoOpWhenAlreadyFinished() {
        var engine = MatchEngine(rules: .standardMix)
        for _ in 0..<4 { engine.score(.a) }
        engine.endManually()
        let finished = engine.state

        engine.endManually(at: Date().addingTimeInterval(60))

        #expect(engine.state == finished)
    }

    @Test("Points scored after endManually are rejected")
    func pointsAfterEndManuallyAreRejected() {
        var engine = MatchEngine(rules: .standardMix)
        for _ in 0..<4 { engine.score(.a) }
        engine.endManually()

        let outcome = engine.score(.b)
        #expect(outcome.wasRejected)
    }

    @Test("A partial (incomplete) game in progress is discarded, not counted, when ending manually")
    func partialGameNotCountedOnManualEnd() {
        var engine = MatchEngine(rules: .standardMix)
        for _ in 0..<4 { engine.score(.a) } // 1 completed game for A
        engine.score(.b) // 15-love in an incomplete 2nd game — should not count as a game for B

        engine.endManually()

        #expect(engine.state.phase.winner == .a)
        #expect(engine.state.sets[0].gamesA == 1 && engine.state.sets[0].gamesB == 0)
    }

    @Test("Undo after endManually reverts just the manual end, not a real point (regression)")
    func undoAfterEndManuallyRevertsOnlyTheEnd() {
        var engine = MatchEngine(rules: .standardMix)
        for _ in 0..<4 { engine.score(.a) } // game 1 -> A
        for _ in 0..<4 { engine.score(.a) } // game 2 -> A
        for _ in 0..<4 { engine.score(.b) } // game 1 -> B
        let beforeEnd = engine.state

        engine.endManually()
        #expect(engine.isFinished)

        engine.undoLastPoint()
        #expect(engine.isFinished == false, "the first undo should revert the manual end, not touch real points")
        #expect(engine.state == beforeEnd)
        #expect(engine.events.count == 12, "no real point event should have been removed")

        // A second undo now behaves normally: it removes the last real point.
        engine.undoLastPoint()
        #expect(engine.events.count == 11)
    }

    @Test("endManually is a no-op for non-mix formats")
    func endManuallyNoOpForNonMixFormats() {
        var engine = MatchEngine(rules: .standardSets)
        for _ in 0..<4 { engine.score(.a) }
        let before = engine.state

        engine.endManually()

        #expect(engine.state == before)
        #expect(engine.isFinished == false)
    }
}
