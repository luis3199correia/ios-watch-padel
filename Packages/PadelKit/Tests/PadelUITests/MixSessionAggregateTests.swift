import Testing
import PadelCore
@testable import PadelUI

@Suite("MixSessionAggregator")
struct MixSessionAggregateTests {

    private func endedRound(gamesA: Int, gamesB: Int) -> MatchState {
        var engine = MatchEngine(rules: .standardMix)
        for _ in 0..<gamesA { for _ in 0..<4 { engine.score(.a) } }
        for _ in 0..<gamesB { for _ in 0..<4 { engine.score(.b) } }
        engine.endManually()
        return engine.state
    }

    @Test("Counts wins, draws, and losses from team A's perspective")
    func countsOutcomes() {
        let rounds = [
            endedRound(gamesA: 4, gamesB: 3), // win
            endedRound(gamesA: 5, gamesB: 2), // win
            endedRound(gamesA: 3, gamesB: 3), // draw
            endedRound(gamesA: 2, gamesB: 4), // loss
            endedRound(gamesA: 5, gamesB: 2), // win
        ]
        let aggregate = MixSessionAggregator.aggregate(rounds)
        #expect(aggregate.wins == 3)
        #expect(aggregate.draws == 1)
        #expect(aggregate.losses == 1)
    }

    @Test("Sums total games won by each side across all rounds")
    func sumsTotalGames() {
        let rounds = [endedRound(gamesA: 4, gamesB: 3), endedRound(gamesA: 5, gamesB: 2), endedRound(gamesA: 3, gamesB: 3)]
        let aggregate = MixSessionAggregator.aggregate(rounds)
        #expect(aggregate.totalGamesA == 12)
        #expect(aggregate.totalGamesB == 8)
        #expect(aggregate.totalGamesLabel == "12-8")
    }

    @Test("No rounds produces an all-zero aggregate")
    func noRounds() {
        let aggregate = MixSessionAggregator.aggregate([])
        #expect(aggregate.wins == 0 && aggregate.draws == 0 && aggregate.losses == 0)
        #expect(aggregate.totalGamesLabel == "0-0")
    }
}
