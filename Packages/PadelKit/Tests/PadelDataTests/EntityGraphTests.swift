import Testing
import Foundation
import SwiftData
import PadelCore
@testable import PadelData

@Suite("PadelData entity graph")
@MainActor
struct EntityGraphTests {

    @Test("An in-memory container builds with all five real models and can fetch each")
    func containerBuildsWithRealSchema() throws {
        let context = try PadelModelContainer.make(inMemory: true).mainContext
        #expect(try context.fetch(FetchDescriptor<Player>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<MatchParticipant>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Match>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<MatchSet>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Session>()).isEmpty)
    }

    @Test("Deleting a Session cascades to delete its rounds")
    func deletingSessionCascadesToRounds() throws {
        let context = try PadelModelContainer.make(inMemory: true).mainContext
        let session = Session(targetDuration: 90 * 60, rules: .standardMix)
        let round = Match(roundIndex: 0, rules: .standardMix)
        round.session = session
        session.rounds = [round]
        context.insert(session)
        try context.save()

        context.delete(session)
        try context.save()

        let remainingMatches = try context.fetch(FetchDescriptor<Match>())
        #expect(remainingMatches.isEmpty)
    }

    @Test("Deleting a Player nullifies the participant's player reference, keeping the match and displayName")
    func deletingPlayerNullifiesParticipantReference() throws {
        let context = try PadelModelContainer.make(inMemory: true).mainContext
        let player = Player(name: "Luís")
        let match = Match(rules: .standardSets)
        let participant = MatchParticipant(team: .a, displayName: "Luís", position: 0, player: player)
        participant.match = match
        match.participants = [participant]
        context.insert(player)
        context.insert(match)
        try context.save()

        context.delete(player)
        try context.save()

        let remainingMatches = try context.fetch(FetchDescriptor<Match>())
        #expect(remainingMatches.count == 1)
        let remainingParticipant = try #require(remainingMatches.first?.participants.first)
        #expect(remainingParticipant.player == nil)
        #expect(remainingParticipant.displayName == "Luís")
    }

    @Test("A Mix round's anonymous opponents have no Player, only a displayName")
    func anonymousOpponentsHaveNoPlayerRecord() throws {
        let context = try PadelModelContainer.make(inMemory: true).mainContext
        let round = Match(rules: .standardMix)
        let opponent1 = MatchParticipant(team: .b, displayName: "Adversário 1", position: 0)
        let opponent2 = MatchParticipant(team: .b, displayName: "Adversário 2", position: 1)
        opponent1.match = round
        opponent2.match = round
        round.participants = [opponent1, opponent2]
        context.insert(round)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Player>()).isEmpty)
        #expect(round.participants.allSatisfy { $0.player == nil })
    }
}
