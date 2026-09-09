import Foundation
import Testing
@testable import PadelCore

@Suite("SetScoring, TieBreakScoring and match format (sets vs pro-set)")
struct SetAndTieBreakTests {

    // MARK: - Regular sets

    @Test("6-0 wins the set outright")
    func sixZeroWinsSet() {
        let set = SetScore(index: 0, gamesA: 6, gamesB: 0)
        let outcome = SetScoring.evaluateAfterRegularGame(set, rules: .standardSets)
        guard case .won(let winner, _) = outcome else {
            Issue.record("6-0 should win the set")
            return
        }
        #expect(winner == .a)
    }

    @Test("6-5 does not win the set (needs 2-game margin)")
    func sixFiveDoesNotWin() {
        let set = SetScore(index: 0, gamesA: 6, gamesB: 5)
        let outcome = SetScoring.evaluateAfterRegularGame(set, rules: .standardSets)
        guard case .ongoing = outcome else {
            Issue.record("6-5 should not decide the set")
            return
        }
    }

    @Test("5-5 -> 7-5 wins the set")
    func sevenFiveWinsSet() {
        let set = SetScore(index: 0, gamesA: 7, gamesB: 5)
        let outcome = SetScoring.evaluateAfterRegularGame(set, rules: .standardSets)
        guard case .won(let winner, _) = outcome else {
            Issue.record("7-5 should win the set")
            return
        }
        #expect(winner == .a)
    }

    @Test("6-6 enters a tie-break")
    func sixSixEntersTieBreak() {
        let set = SetScore(index: 0, gamesA: 6, gamesB: 6)
        let outcome = SetScoring.evaluateAfterRegularGame(set, rules: .standardSets)
        guard case .enteredTieBreak = outcome else {
            Issue.record("6-6 should enter a tie-break")
            return
        }
    }

    // MARK: - Pro-set format

    @Test("Pro-set to 9: 9-7 wins the whole match outright (no separate sets)")
    func proSetNineWinsMatch() {
        let rules = MatchRules.standardProSet // targetGames: 9
        #expect(rules.setsNeededToWin == 1)
        #expect(rules.gamesToWinSet == 9)
        #expect(rules.tieBreakAtGames == 8)

        let set = SetScore(index: 0, gamesA: 9, gamesB: 7)
        let outcome = SetScoring.evaluateAfterRegularGame(set, rules: rules)
        guard case .won(let winner, _) = outcome else {
            Issue.record("9-7 should win a pro-set to 9")
            return
        }
        #expect(winner == .a)
        // MatchWinnerEvaluator relies on SetScore.winner being populated by the reducer, not just raw games.
        #expect(MatchWinnerEvaluator.winner(in: [set], rules: rules) == nil)
    }

    @Test("Pro-set to 9: 8-8 enters a tie-break")
    func proSetEightEightEntersTieBreak() {
        let rules = MatchRules.standardProSet
        let set = SetScore(index: 0, gamesA: 8, gamesB: 8)
        let outcome = SetScoring.evaluateAfterRegularGame(set, rules: rules)
        guard case .enteredTieBreak = outcome else {
            Issue.record("8-8 should enter a tie-break in a pro-set to 9")
            return
        }
    }

    @Test("Full match: pro-set finishes after exactly one set")
    func proSetMatchFinishesAfterOneSet() {
        var engine = MatchEngine(rules: .standardProSet)
        for _ in 0..<(9 * 4) { // 9 love games for A: 4 points each
            engine.score(.a)
        }
        #expect(engine.isFinished)
        #expect(engine.state.sets.count == 1)
        #expect(engine.state.phase.winner == .a)
    }

    // MARK: - Tie-break scoring

    @Test("Tie-break: first to 7 with 2-point margin wins")
    func tieBreakWinsAtSeven() {
        let game = GameScore(rawA: 6, rawB: 3, isTieBreak: true)
        let outcome = TieBreakScoring.awardPoint(to: .a, in: game, targetPoints: 7)
        guard case .won(let winner, let final, _) = outcome else {
            Issue.record("7-3 should win the tie-break")
            return
        }
        #expect(winner == .a)
        #expect(final.rawA == 7)
    }

    @Test("Tie-break: 6-6 does not win, needs 2-point margin, continues to e.g. 8-6")
    func tieBreakNeedsTwoPointMargin() {
        let game = GameScore(rawA: 6, rawB: 6, isTieBreak: true)
        let afterFirst = TieBreakScoring.awardPoint(to: .a, in: game, targetPoints: 7)
        guard case .ongoing(let updated) = afterFirst else {
            Issue.record("7-6 should not yet win (needs 2-point margin)")
            return
        }
        let final = TieBreakScoring.awardPoint(to: .a, in: updated, targetPoints: 7)
        guard case .won(let winner, _, _) = final else {
            Issue.record("8-6 should win the tie-break")
            return
        }
        #expect(winner == .a)
    }

    @Test("Tie-break set score is recorded as e.g. 7-6 with the tie-break points in the summary")
    func tieBreakSetSummaryFormatting() {
        let tieBreak = TieBreakScore(pointsA: 7, pointsB: 5)
        let set = SetScore(index: 0, gamesA: 7, gamesB: 6, tieBreak: tieBreak, winner: .a, endedAt: Date())
        #expect(ScoreFormatter.setScoreSummary([set]) == "7-6(5)")
    }

    @Test("Playing a full tie-break via the engine records the exact final tie-break score (regression: winner's score must not be off by one)")
    func tieBreakFinalScoreIsRecordedExactly() {
        var engine = MatchEngine(rules: .standardSets)
        for _ in 0..<6 {
            for _ in 0..<4 { engine.score(.a) }
            for _ in 0..<4 { engine.score(.b) }
        }
        // 6-6 in games: tie-break under way. Alternate to 5-5, then A wins the last 2 points (7-5).
        for _ in 0..<5 {
            engine.score(.a)
            engine.score(.b)
        }
        engine.score(.a)
        engine.score(.a)

        let finishedSet = engine.state.sets.first { $0.winner != nil }
        #expect(finishedSet?.gamesA == 7 && finishedSet?.gamesB == 6)
        #expect(finishedSet?.tieBreak == TieBreakScore(pointsA: 7, pointsB: 5, startedAt: finishedSet?.tieBreak?.startedAt))
    }

    // MARK: - Serve rotation within a tie-break

    @Test("Tie-break serve: point 1 by first server, points 2-3 by opponent, points 4-5 back to first server")
    func tieBreakServeRotation() {
        #expect(ServeRotation.tieBreakServer(pointNumber: 1, firstServer: .a) == .a)
        #expect(ServeRotation.tieBreakServer(pointNumber: 2, firstServer: .a) == .b)
        #expect(ServeRotation.tieBreakServer(pointNumber: 3, firstServer: .a) == .b)
        #expect(ServeRotation.tieBreakServer(pointNumber: 4, firstServer: .a) == .a)
        #expect(ServeRotation.tieBreakServer(pointNumber: 5, firstServer: .a) == .a)
        #expect(ServeRotation.tieBreakServer(pointNumber: 6, firstServer: .a) == .b)
    }

    // MARK: - Match winner across sets

    @Test("Best of 3: match ends 2-1 in sets, not before")
    func bestOfThreeEndsAtTwoSets() {
        let oneSetEach = [
            SetScore(index: 0, gamesA: 6, gamesB: 3, winner: .a),
            SetScore(index: 1, gamesA: 4, gamesB: 6, winner: .b),
        ]
        #expect(MatchWinnerEvaluator.winner(in: oneSetEach, rules: .standardSets) == nil)

        let decidingSet = oneSetEach + [SetScore(index: 2, gamesA: 6, gamesB: 2, winner: .a)]
        #expect(MatchWinnerEvaluator.winner(in: decidingSet, rules: .standardSets) == .a)
    }
}
