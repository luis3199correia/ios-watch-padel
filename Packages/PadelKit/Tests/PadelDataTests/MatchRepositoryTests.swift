import Testing
import Foundation
import SwiftData
import PadelCore
@testable import PadelData

@Suite("MatchRepository")
@MainActor
struct MatchRepositoryTests {

    private func standaloneParticipants() -> [ParticipantSlot] {
        [
            ParticipantSlot(team: .a, displayName: "Luís", position: 0),
            ParticipantSlot(team: .a, displayName: "Rui", position: 1),
            ParticipantSlot(team: .b, displayName: "Tiago", position: 0),
            ParticipantSlot(team: .b, displayName: "André", position: 1),
        ]
    }

    @Test("scheduleMatch creates a scheduled match with its 4 participants")
    func scheduleMatchCreatesParticipants() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let match = MatchRepository.scheduleMatch(
            rules: .standardSets, scheduledAt: .now, location: "Court Central",
            participants: standaloneParticipants(), in: context
        )

        #expect(match.status == .scheduled)
        #expect(match.participants.count == 4)
    }

    @Test("start transitions a scheduled match to inProgress and sets startedAt")
    func startTransitionsStatus() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let match = MatchRepository.scheduleMatch(
            rules: .standardSets, scheduledAt: .now, location: "", participants: [], in: context
        )
        let startDate = Date(timeIntervalSince1970: 1_000)
        MatchRepository.start(match, at: startDate)

        #expect(match.status == .inProgress)
        #expect(match.startedAt == startDate)
    }

    @Test("start is a no-op once the match is no longer scheduled")
    func startIsNoOpWhenAlreadyStarted() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let match = MatchRepository.scheduleMatch(
            rules: .standardSets, scheduledAt: .now, location: "", participants: [], in: context
        )
        MatchRepository.start(match, at: Date(timeIntervalSince1970: 1_000))
        MatchRepository.start(match, at: Date(timeIntervalSince1970: 2_000))

        #expect(match.startedAt == Date(timeIntervalSince1970: 1_000))
    }

    @Test("saveProgress persists the engine's event log onto the match")
    func saveProgressPersistsEvents() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let match = MatchRepository.scheduleMatch(
            rules: .standardSets, scheduledAt: .now, location: "", participants: [], in: context
        )
        var engine = MatchEngine(rules: .standardSets)
        engine.score(.a)
        engine.score(.a)

        MatchRepository.saveProgress(match, engine: engine)

        #expect(match.eventCount == 2)
        #expect(match.events.map(\.team) == [.a, .a])
    }

    @Test("finish writes the MatchSet rows and outcome from a manually-ended Mix round")
    func finishWritesSetsAndOutcome() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let match = MatchRepository.scheduleMatch(
            rules: .standardMix, scheduledAt: .now, location: "", participants: [], in: context
        )
        var engine = MatchEngine(rules: .standardMix)
        engine.score(.a)
        engine.score(.a)
        engine.score(.a)
        engine.score(.a) // team A wins the first game, 4-0
        engine.endManually()

        let finishDate = Date(timeIntervalSince1970: 5_000)
        MatchRepository.finish(match, engine: engine, at: finishDate, in: context)

        #expect(match.status == .finished)
        #expect(match.outcomeKindRaw == "win")
        #expect(match.winnerTeamRaw == "a")
        #expect(match.endedAt == finishDate)
        #expect(match.sets.count == 1)
        #expect(match.sets.first?.gamesA == 1)
        #expect(match.sets.first?.gamesB == 0)
        #expect(match.sets.first?.winnerTeamRaw == "a")
    }

    @Test("finish is a no-op when the engine hasn't actually finished")
    func finishIsNoOpWhenNotFinished() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let match = MatchRepository.scheduleMatch(
            rules: .standardMix, scheduledAt: .now, location: "", participants: [], in: context
        )
        var engine = MatchEngine(rules: .standardMix)
        engine.score(.a)

        MatchRepository.finish(match, engine: engine, in: context)

        #expect(match.status == .scheduled)
        #expect(match.sets.isEmpty)
    }

    @Test("upcoming returns only scheduled standalone matches, soonest first")
    func upcomingReturnsScheduledStandaloneMatches() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let soon = Date(timeIntervalSince1970: 1_000)
        let later = Date(timeIntervalSince1970: 2_000)
        let laterMatch = MatchRepository.scheduleMatch(rules: .standardSets, scheduledAt: later, location: "", participants: [], in: context)
        let soonMatch = MatchRepository.scheduleMatch(rules: .standardSets, scheduledAt: soon, location: "", participants: [], in: context)
        let startedMatch = MatchRepository.scheduleMatch(rules: .standardSets, scheduledAt: soon, location: "", participants: [], in: context)
        MatchRepository.start(startedMatch)

        let upcoming = try MatchRepository.upcoming(in: context)

        #expect(upcoming.map(\.id) == [soonMatch.id, laterMatch.id])
    }

    @Test("history returns only finished standalone matches, most recent first")
    func historyReturnsFinishedStandaloneMatches() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))

        let earlyMatch = MatchRepository.scheduleMatch(rules: .standardMix, scheduledAt: .now, location: "", participants: [], in: context)
        var earlyEngine = MatchEngine(rules: .standardMix)
        earlyEngine.score(.a)
        earlyEngine.endManually()
        MatchRepository.finish(earlyMatch, engine: earlyEngine, at: Date(timeIntervalSince1970: 1_000), in: context)

        let lateMatch = MatchRepository.scheduleMatch(rules: .standardMix, scheduledAt: .now, location: "", participants: [], in: context)
        var lateEngine = MatchEngine(rules: .standardMix)
        lateEngine.score(.b)
        lateEngine.endManually()
        MatchRepository.finish(lateMatch, engine: lateEngine, at: Date(timeIntervalSince1970: 2_000), in: context)

        let stillScheduled = MatchRepository.scheduleMatch(rules: .standardMix, scheduledAt: .now, location: "", participants: [], in: context)
        _ = stillScheduled

        let history = try MatchRepository.history(in: context)

        #expect(history.map(\.id) == [lateMatch.id, earlyMatch.id])
    }
}
