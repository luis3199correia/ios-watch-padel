import Testing
import Foundation
import SwiftData
@testable import PadelData

@Suite("PlayerRepository")
@MainActor
struct PlayerRepositoryTests {

    @Test("upsert creates a new player when none exists with that id")
    func upsertCreates() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let id = UUID()
        let player = try PlayerRepository.upsert(id: id, name: "Luís", in: context)

        #expect(player.id == id)
        #expect(player.name == "Luís")
        #expect(try PlayerRepository.all(in: context).count == 1)
    }

    @Test("upsert updates the existing player instead of creating a duplicate")
    func upsertUpdates() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let id = UUID()
        try PlayerRepository.upsert(id: id, name: "Luís", in: context)
        try PlayerRepository.upsert(id: id, name: "Luís Correia", isMe: true, in: context)

        let all = try PlayerRepository.all(in: context)
        #expect(all.count == 1)
        #expect(all.first?.name == "Luís Correia")
        #expect(all.first?.isMe == true)
    }

    @Test("all() returns players sorted by name")
    func allSortedByName() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        try PlayerRepository.upsert(name: "Tiago", in: context)
        try PlayerRepository.upsert(name: "André", in: context)
        try PlayerRepository.upsert(name: "Marta", in: context)

        let names = try PlayerRepository.all(in: context).map(\.name)
        #expect(names == ["André", "Marta", "Tiago"])
    }

    @Test("me() is nil until a player is marked isMe")
    func meIsNilInitially() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        try PlayerRepository.upsert(name: "Rui", in: context)
        #expect(try PlayerRepository.me(in: context) == nil)
    }

    @Test("me() returns the player marked isMe")
    func meReturnsOwner() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        try PlayerRepository.upsert(name: "Rui", in: context)
        let owner = try PlayerRepository.upsert(name: "Luís", isMe: true, in: context)

        #expect(try PlayerRepository.me(in: context)?.id == owner.id)
    }
}
