import Testing
import SwiftData
@testable import PadelData

/// If this suite fails, it's not a code bug — it means in-memory SwiftData doesn't work under
/// `swift test --disable-sandbox` on this CI runner, and the whole persistence-layer testing
/// strategy needs to change (see the plan's Phase 0 risk notes). Nothing else in `PadelData`
/// should be built until this is green.
@Suite("SwiftData in-memory container smoke test")
struct SchemaSmokeTests {

    @Test("An in-memory container can be created, inserted into, saved, and fetched from")
    @MainActor
    func inMemoryContainerRoundTrips() throws {
        let container = try PadelModelContainer.make(inMemory: true)
        let context = container.mainContext

        context.insert(SmokeEntity(name: "Luís"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SmokeEntity>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Luís")
    }
}
