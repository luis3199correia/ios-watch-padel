import Testing
import PadelCore
@testable import PadelUI

@Suite("PointTimelineBuilder")
struct PointTimelineBuilderTests {

    @Test("Empty event log produces an empty timeline")
    func emptyLog() {
        let engine = MatchEngine(rules: .standardSets)
        let dots = PointTimelineBuilder.build(events: engine.events, state: engine.state)
        #expect(dots.isEmpty)
    }

    @Test("Dot count and team sequence match the event log")
    func dotCountAndSequenceMatchEvents() {
        var engine = MatchEngine(rules: .standardSets)
        let teams: [Team] = [.a, .b, .a, .a, .b]
        for team in teams { engine.score(team) }

        let dots = PointTimelineBuilder.build(events: engine.events, state: engine.state)
        #expect(dots.count == teams.count)
        #expect(dots.map(\.team) == teams)
    }

    @Test("No dot is flagged as a sudden-death decider under classic advantage")
    func noSuddenDeathUnderClassicAdvantage() {
        var engine = MatchEngine(rules: .standardSets) // classicAdvantage
        for _ in 0..<3 { engine.score(.a) }
        for _ in 0..<3 { engine.score(.b) } // 40-40
        for _ in 0..<10 { engine.score(.a); engine.score(.b) } // repeated deuces, then A wins
        engine.score(.a)
        engine.score(.a)

        let dots = PointTimelineBuilder.build(events: engine.events, state: engine.state)
        #expect(dots.allSatisfy { $0.isSuddenDeathDecider == false })
    }

    @Test("Exactly one dot is flagged for a golden-point-decided game")
    func exactlyOneSuddenDeathDeciderUnderGoldenPoint() {
        var engine = MatchEngine(rules: MatchRules(format: .sets(bestOf: 3), deuceRule: .goldenPoint))
        for _ in 0..<3 { engine.score(.a) }
        for _ in 0..<3 { engine.score(.b) } // 40-40 under golden point
        engine.score(.b) // decides the game outright

        let dots = PointTimelineBuilder.build(events: engine.events, state: engine.state)
        #expect(dots.filter(\.isSuddenDeathDecider).count == 1)
        #expect(dots.last?.isSuddenDeathDecider == true)
        #expect(dots.last?.team == .b)
    }
}
