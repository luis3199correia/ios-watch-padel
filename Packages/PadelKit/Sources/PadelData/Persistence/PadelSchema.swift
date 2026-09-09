import Foundation
import SwiftData

enum PadelSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [Player.self, MatchParticipant.self, Match.self, MatchSet.self, Session.self]
    }
}

enum PadelMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [PadelSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

public enum PadelModelContainer {
    /// Bypasses `Schema(versionedSchema:)` + `migrationPlan:` for now and builds the container
    /// straight from the model list — a deliberate simplification to isolate a CI crash
    /// (signal 5) that happens even for the simplest possible test (create container, fetch
    /// each type, no data). If this resolves it, the versioned-schema/migration-plan indirection
    /// was the trigger and can be reintroduced deliberately later; if not, the problem is in the
    /// model/relationship graph itself.
    public static func make(inMemory: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(
            for: Player.self, MatchParticipant.self, Match.self, MatchSet.self, Session.self,
            configurations: configuration
        )
    }
}
