import Testing
import Foundation
import SwiftData
import PadelCore
@testable import PadelData

@Suite("SessionRepository")
@MainActor
struct SessionRepositoryTests {

    private func makeLineup(in context: ModelContext) throws -> [Player] {
        [
            try PlayerRepository.upsert(name: "Luís", isMe: true, in: context),
            try PlayerRepository.upsert(name: "Rui", in: context),
        ]
    }

    @Test("start creates a scheduled session with the shared \"my team\" lineup")
    func startCreatesSessionWithLineup() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let lineup = try makeLineup(in: context)
        let session = SessionRepository.start(
            rules: .standardMix, scheduledAt: .now, location: "Padel Norte",
            targetDuration: 90 * 60, targetRoundDuration: 15 * 60, lineup: lineup, in: context
        )

        #expect(session.status == .scheduled)
        #expect(session.lineup.count == 2)
        #expect(session.lineup.allSatisfy { $0.team == .a })
        #expect(Set(session.lineup.map(\.position)) == [0, 1])
    }

    @Test("addRound starts an in-progress round with 2 anonymous opponents, indexed sequentially")
    func addRoundCreatesAnonymousOpponents() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let session = SessionRepository.start(
            rules: .standardMix, scheduledAt: .now, location: "", targetDuration: 90 * 60,
            targetRoundDuration: nil, lineup: try makeLineup(in: context), in: context
        )

        let round1 = SessionRepository.addRound(to: session, in: context)
        let round2 = SessionRepository.addRound(to: session, in: context)

        #expect(round1.roundIndex == 0)
        #expect(round2.roundIndex == 1)
        #expect(round1.status == .inProgress)
        #expect(round1.participants.count == 2)
        #expect(round1.participants.allSatisfy { $0.team == .b && $0.player == nil })
        #expect(Set(round1.participants.map(\.displayName)) == ["Adversário 1", "Adversário 2"])
    }

    @Test("finishRound delegates to MatchRepository.finish")
    func finishRoundWritesSets() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let session = SessionRepository.start(
            rules: .standardMix, scheduledAt: .now, location: "", targetDuration: 90 * 60,
            targetRoundDuration: nil, lineup: try makeLineup(in: context), in: context
        )
        let round = SessionRepository.addRound(to: session, in: context)

        var engine = MatchEngine(rules: session.rules)
        engine.score(.a)
        engine.endManually()
        SessionRepository.finishRound(round, engine: engine, in: context)

        #expect(round.status == .finished)
        #expect(round.sets.count == 1)
    }

    @Test("finish marks the session finished and stamps endedAt")
    func finishMarksSessionFinished() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let session = SessionRepository.start(
            rules: .standardMix, scheduledAt: .now, location: "", targetDuration: 90 * 60,
            targetRoundDuration: nil, lineup: try makeLineup(in: context), in: context
        )
        let endDate = Date(timeIntervalSince1970: 9_000)
        SessionRepository.finish(session, at: endDate)

        #expect(session.status == .finished)
        #expect(session.endedAt == endDate)
    }

    @Test("history returns only finished sessions, most recent first")
    func historyReturnsFinishedSessions() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let lineup = try makeLineup(in: context)

        let earlySession = SessionRepository.start(
            rules: .standardMix, scheduledAt: .now, location: "", targetDuration: 90 * 60,
            targetRoundDuration: nil, lineup: lineup, in: context
        )
        SessionRepository.finish(earlySession, at: Date(timeIntervalSince1970: 1_000))

        let lateSession = SessionRepository.start(
            rules: .standardMix, scheduledAt: .now, location: "", targetDuration: 90 * 60,
            targetRoundDuration: nil, lineup: lineup, in: context
        )
        SessionRepository.finish(lateSession, at: Date(timeIntervalSince1970: 2_000))

        let stillScheduled = SessionRepository.start(
            rules: .standardMix, scheduledAt: .now, location: "", targetDuration: 90 * 60,
            targetRoundDuration: nil, lineup: lineup, in: context
        )
        _ = stillScheduled

        let history = try SessionRepository.history(in: context)

        #expect(history.map(\.id) == [lateSession.id, earlySession.id])
    }

    @Test("ParticipantRoster.resolve unions the session's lineup with the round's own opponents")
    func rosterUnionsLineupAndOpponents() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let session = SessionRepository.start(
            rules: .standardMix, scheduledAt: .now, location: "", targetDuration: 90 * 60,
            targetRoundDuration: nil, lineup: try makeLineup(in: context), in: context
        )
        let round = SessionRepository.addRound(to: session, in: context)

        let roster = ParticipantRoster.resolve(for: round)

        #expect(roster.count == 4)
        #expect(roster.filter { $0.team == .a }.count == 2)
        #expect(roster.filter { $0.team == .b }.count == 2)
    }
}
