import Foundation

public enum PersistenceError: Error, Equatable {
    case encodingFailed(String)
    case decodingFailed(String)
}

/// Wraps a persisted `Codable` payload with a schema version. `SchemaMigrationPlan` can't see
/// inside a `Data` column, so blobs (`Match.rulesData`/`eventsData`, etc.) need their own
/// versioning axis independent of SwiftData's own schema versioning.
public struct VersionedPayload<T: Codable>: Codable {
    public let schemaVersion: Int
    public let payload: T

    public init(schemaVersion: Int, payload: T) {
        self.schemaVersion = schemaVersion
        self.payload = payload
    }
}

/// Shared coder for every JSON blob persisted by `PadelData`.
///
/// The date strategy must stay `.deferredToDate` (the `JSONEncoder`/`JSONDecoder` default) —
/// never `.iso8601`. `PointEvent.timestamp` and the various `startedAt`/`endedAt` fields on
/// `PadelCore` types participate in `MatchState`'s synthesized `Equatable`; ISO-8601 truncates
/// to whole seconds, which would make a round-tripped log produce a `MatchState` that is no
/// longer `==` the original and silently break decisions.md #1's replay invariant.
public enum PadelJSON {
    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys] // deterministic bytes, diffable in tests
        return encoder
    }()

    public static let decoder = JSONDecoder()

    public static func encode<T: Codable>(_ value: T, schemaVersion: Int = 1) throws -> Data {
        do {
            return try encoder.encode(VersionedPayload(schemaVersion: schemaVersion, payload: value))
        } catch {
            throw PersistenceError.encodingFailed(String(describing: error))
        }
    }

    public static func decode<T: Codable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(VersionedPayload<T>.self, from: data).payload
        } catch {
            throw PersistenceError.decodingFailed(String(describing: error))
        }
    }
}
