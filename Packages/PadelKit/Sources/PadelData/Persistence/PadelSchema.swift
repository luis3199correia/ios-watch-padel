import Foundation
import SwiftData

/// Throwaway entity for `SchemaSmokeTests`, kept as `PadelSchemaV1`'s only model until Fase 2
/// adds the real ones — versioned schemas are nearly free to set up now and are the only way to
/// ship a migration later without a device to test one on.
@Model
final class SmokeEntity {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

enum PadelSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [SmokeEntity.self] }
}

enum PadelMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [PadelSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

public enum PadelModelContainer {
    public static func make(inMemory: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(
            for: Schema(versionedSchema: PadelSchemaV1.self),
            migrationPlan: PadelMigrationPlan.self,
            configurations: configuration
        )
    }
}
