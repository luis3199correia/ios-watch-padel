import Foundation
import SwiftData

/// Throwaway entity for `SchemaSmokeTests` — proves that an in-memory `ModelContainer` actually
/// works under `swift test --disable-sandbox` in this project's CI, before any real entity is
/// built on top of that assumption. Replaced by the real schema in a later step.
@Model
final class SmokeEntity {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

public enum PadelModelContainer {
    public static func make(inMemory: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: SmokeEntity.self, configurations: configuration)
    }
}
