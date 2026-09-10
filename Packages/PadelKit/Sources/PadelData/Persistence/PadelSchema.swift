import Foundation
import SwiftData

enum PadelSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [
            Player.self, MatchParticipant.self, Match.self, MatchSet.self, Session.self,
            CourtCalibrationRecord.self, StrokeProfileRecord.self, Shot.self,
        ]
    }
}

enum PadelMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [PadelSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

public enum PadelModelContainer {
    public static func make(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema(versionedSchema: PadelSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, migrationPlan: PadelMigrationPlan.self, configurations: configuration)
    }
}
