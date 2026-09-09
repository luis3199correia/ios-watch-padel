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
        context.insert(session)
        context.insert(round)
        round.session = session // set only one side of the inverse pair; SwiftData syncs session.rounds
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
        context.insert(player)
        context.insert(match)
        context.insert(participant)
        participant.match = match // set only one side; SwiftData syncs match.participants
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
        context.insert(round)
        context.insert(opponent1)
        context.insert(opponent2)
        opponent1.match = round // set only one side; SwiftData syncs round.participants
        opponent2.match = round
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Player>()).isEmpty)
        #expect(round.participants.allSatisfy { $0.player == nil })
    }
}
