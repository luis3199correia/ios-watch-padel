import Testing
import PadelCore
@testable import PadelUI

@Suite("LiveScoreViewModel.endRound (Mix)")
struct MixRoundViewModelTests {

    @Test("4-3 declares team A the winner")
    func endsWithAWinning() {
        let vm = LiveScoreViewModel(engine: MatchEngine(rules: .standardMix), teamLabels: .mix)
        for _ in 0..<4 { vm.score(.a) }
        for _ in 0..<4 { vm.score(.a) }
        for _ in 0..<4 { vm.score(.b) }
        vm.endRound()
        #expect(vm.engine.state.phase.winner == .a)
    }

    @Test("3-3 (equal games) is a draw")
    func equalGamesIsDraw() {
        let vm = LiveScoreViewModel(engine: MatchEngine(rules: .standardMix), teamLabels: .mix)
        for _ in 0..<4 { vm.score(.a) }
        for _ in 0..<4 { vm.score(.b) }
        vm.endRound()
        #expect(vm.engine.state.phase.isDraw)
    }

    @Test("0-0 (no games played at all) is also a draw")
    func noGamesPlayedIsDraw() {
        let vm = LiveScoreViewModel(engine: MatchEngine(rules: .standardMix), teamLabels: .mix)
        vm.endRound()
        #expect(vm.engine.state.phase.isDraw)
    }

    @Test("An incomplete in-progress game isn't counted for either team")
    func incompleteGameNotCounted() {
        let vm = LiveScoreViewModel(engine: MatchEngine(rules: .standardMix), teamLabels: .mix)
        for _ in 0..<4 { vm.score(.a) } // 1 completed game for A
        vm.score(.b) // 15-love in an incomplete 2nd game — should not count for B
        vm.endRound()
        #expect(vm.engine.state.phase.winner == .a)
    }

    @Test("Undo right after endRound reverts just the round end, not the last real point (regression)")
    func undoAfterEndRoundRevertsOnlyTheEnd() {
        let vm = LiveScoreViewModel(engine: MatchEngine(rules: .standardMix), teamLabels: .mix)
        for _ in 0..<4 { vm.score(.a) }
        for _ in 0..<4 { vm.score(.a) }
        for _ in 0..<4 { vm.score(.b) }
        let beforeEnd = vm.engine.state
        let eventCountBeforeEnd = vm.engine.events.count

        vm.endRound()
        #expect(vm.isFinished)

        vm.undo()
        #expect(vm.isFinished == false)
        #expect(vm.engine.state == beforeEnd)
        #expect(vm.engine.events.count == eventCountBeforeEnd)
    }
}
