import Testing
import PadelCore
@testable import PadelUI

@Suite("LiveScoreViewModel")
struct LiveScoreViewModelTests {

    @Test("Point labels and set/game counts reflect scripted points")
    func labelsMatchScriptedPoints() {
        let vm = LiveScoreViewModel(engine: MatchEngine(rules: .standardSets), teamLabels: .mix)
        vm.score(.a)
        vm.score(.a)
        #expect(vm.pointsLabel(for: .a) == "30")
        #expect(vm.pointsLabel(for: .b) == "0")
        #expect(vm.currentSetGamesLabel == "0-0")
        #expect(vm.setsWonA == 0 && vm.setsWonB == 0)
    }

    @Test("canUndo is false at kickoff and true after one point")
    func canUndoTransitions() {
        let vm = LiveScoreViewModel(engine: MatchEngine(rules: .standardSets), teamLabels: .mix)
        #expect(vm.canUndo == false)
        vm.score(.a)
        #expect(vm.canUndo == true)
    }

    @Test("Undo restores the previous point label")
    func undoRestoresPreviousLabel() {
        let vm = LiveScoreViewModel(engine: MatchEngine(rules: .standardSets), teamLabels: .mix)
        vm.score(.a)
        vm.score(.a)
        #expect(vm.pointsLabel(for: .a) == "30")
        vm.undo()
        #expect(vm.pointsLabel(for: .a) == "15")
    }

    @Test("A finished match rejects further points without changing labels")
    func finishedMatchRejectsPoints() {
        let vm = LiveScoreViewModel(
            engine: MatchEngine(rules: MatchRules(format: .sets(bestOf: 1), deuceRule: .classicAdvantage)),
            teamLabels: .mix
        )
        for _ in 0..<24 { vm.score(.a) } // wins 6 love games -> set + match won
        #expect(vm.isFinished)
        let before = vm.pointsLabel(for: .a)
        let outcome = vm.score(.b)
        #expect(outcome.wasRejected)
        #expect(vm.pointsLabel(for: .a) == before)
    }

    @Test("Tie-break labels are the raw point count, not 0/15/30/40")
    func tieBreakLabelsAreRawCounts() {
        let vm = LiveScoreViewModel(engine: MatchEngine(rules: .standardSets), teamLabels: .mix)
        for _ in 0..<6 {
            for _ in 0..<4 { vm.score(.a) } // A wins a love game
            for _ in 0..<4 { vm.score(.b) } // B wins a love game -> games end up 6-6
        }
        #expect(vm.isTieBreak)
        vm.score(.a)
        vm.score(.a)
        #expect(vm.pointsLabel(for: .a) == "2")
    }

    @Test("deuceBadge is non-nil exactly when engine.isGoldenPointNow, for golden point")
    func deuceBadgeMatchesGoldenPoint() {
        let vm = LiveScoreViewModel(
            engine: MatchEngine(rules: MatchRules(format: .sets(bestOf: 3), deuceRule: .goldenPoint)),
            teamLabels: .mix
        )
        for _ in 0..<3 { vm.score(.a) }
        for _ in 0..<3 { vm.score(.b) } // 40-40 under golden point
        #expect(vm.engine.isGoldenPointNow)
        #expect(vm.deuceBadge == "PONTO DE OURO")
    }

    @Test("deuceBadge is nil during classic advantage, which never triggers sudden death")
    func deuceBadgeNilUnderClassicAdvantage() {
        let vm = LiveScoreViewModel(engine: MatchEngine(rules: .standardSets), teamLabels: .mix)
        for _ in 0..<3 { vm.score(.a) }
        for _ in 0..<3 { vm.score(.b) } // 40-40
        #expect(vm.engine.isGoldenPointNow == false)
        #expect(vm.deuceBadge == nil)
    }

    @Test("deuceBadge is nil before the star point limit, then STAR POINT once reached")
    func deuceBadgeMatchesStarPoint() {
        let vm = LiveScoreViewModel(
            engine: MatchEngine(rules: MatchRules(format: .sets(bestOf: 3), deuceRule: .starPoint(deuceLimit: 1))),
            teamLabels: .mix
        )
        for _ in 0..<3 { vm.score(.a) }
        for _ in 0..<3 { vm.score(.b) } // 1st deuce, limit is 1 -> sudden death now
        #expect(vm.engine.isGoldenPointNow)
        #expect(vm.deuceBadge == "STAR POINT")
    }
}
