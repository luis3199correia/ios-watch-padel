import Testing
import Foundation
import PadelCore
@testable import PadelData

@Suite("PadelJSON")
struct PadelJSONTests {

    @Test("Date round-trips exactly, including sub-second precision (the .iso8601 trap)")
    func dateRoundTripsExactly() throws {
        let original = Date(timeIntervalSince1970: 1_757_430_123.456789)
        let data = try PadelJSON.encode(original)
        let decoded = try PadelJSON.decode(Date.self, from: data)
        #expect(decoded == original)
    }

    @Test("Every MatchFormat case round-trips")
    func matchFormatCases() throws {
        let formats: [MatchFormat] = [.sets(bestOf: 3), .proSet(targetGames: 9), .mix]
        for format in formats {
            let decoded = try PadelJSON.decode(MatchFormat.self, from: try PadelJSON.encode(format))
            #expect(decoded == format)
        }
    }

    @Test("Every DeuceRule case round-trips")
    func deuceRuleCases() throws {
        let rules: [DeuceRule] = [.classicAdvantage, .goldenPoint, .starPoint(deuceLimit: 3)]
        for rule in rules {
            let decoded = try PadelJSON.decode(DeuceRule.self, from: try PadelJSON.encode(rule))
            #expect(decoded == rule)
        }
    }

    @Test("Every MatchOutcome case round-trips, nested inside MatchPhase.finished")
    func matchOutcomeCasesNestedInPhase() throws {
        let phases: [MatchPhase] = [
            .notStarted, .inProgress,
            .finished(outcome: .win(.a), at: .now),
            .finished(outcome: .draw, at: .now),
        ]
        for phase in phases {
            let decoded = try PadelJSON.decode(MatchPhase.self, from: try PadelJSON.encode(phase))
            #expect(decoded == phase)
        }
    }

    @Test("An empty event log round-trips")
    func emptyEventLog() throws {
        let events: [PointEvent] = []
        let decoded = try PadelJSON.decode([PointEvent].self, from: try PadelJSON.encode(events))
        #expect(decoded.isEmpty)
    }

    @Test("A full match's worth of events round-trips element-for-element")
    func largeEventLogRoundTrips() throws {
        var engine = MatchEngine(rules: .standardSets)
        for i in 0..<48 { engine.score(i % 2 == 0 ? .a : .b) }

        let decoded = try PadelJSON.decode([PointEvent].self, from: try PadelJSON.encode(engine.events))
        #expect(decoded == engine.events)
    }

    @Test("A persisted MatchState round-trips through encode/decode/replay unchanged")
    func matchStateSurvivesEncodeDecodeReplay() throws {
        var engine = MatchEngine(rules: MatchRules(format: .sets(bestOf: 3), deuceRule: .starPointDefault))
        for _ in 0..<3 { engine.score(.a) }
        for _ in 0..<3 { engine.score(.b) }
        engine.score(.b)
        engine.score(.b)

        let rulesData = try PadelJSON.encode(engine.rules)
        let eventsData = try PadelJSON.encode(engine.events)

        let decodedRules = try PadelJSON.decode(MatchRules.self, from: rulesData)
        let decodedEvents = try PadelJSON.decode([PointEvent].self, from: eventsData)
        let replayed = ScoringReducer.replay(decodedEvents, rules: decodedRules, startedAt: engine.state.startedAt)

        #expect(replayed == engine.state)
    }
}
