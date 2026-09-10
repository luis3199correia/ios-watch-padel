import Testing
import Foundation
import SwiftData

@Model
final class DiagnosticPing {
    var id: UUID = UUID()
    var value: String = ""

    init(id: UUID = UUID(), value: String = "") {
        self.id = id
        self.value = value
    }
}

@Suite("Diagnostic: bare SwiftData container, no relationships")
@MainActor
struct DiagnosticContainerTests {

    @Test("A single-entity, relationship-free in-memory container can fetch")
    func bareContainerFetches() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DiagnosticPing.self, configurations: configuration)
        let context = ModelContext(container)
        #expect(try context.fetch(FetchDescriptor<DiagnosticPing>()).isEmpty)
    }
}
