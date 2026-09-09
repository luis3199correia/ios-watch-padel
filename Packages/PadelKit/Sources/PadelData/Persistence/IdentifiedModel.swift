import Foundation
import SwiftData

/// A `@Model` whose identity is a stable `UUID`, enforced at the repository layer via upsert
/// rather than `@Attribute(.unique)` — unique constraints block a future CloudKit activation
/// and interact badly with upserts on iOS 17 (decisions.md #6).
///
/// Each conformer implements `idPredicate` with a **concrete** `#Predicate<Self>` (never a
/// generic one over the protocol) — a fully generic predicate over a protocol-constrained type
/// is the known failure mode for the predicate macro's key-path translation.
public protocol UUIDIdentifiedModel: PersistentModel {
    var id: UUID { get }
    static func idPredicate(_ id: UUID) -> Predicate<Self>
}

extension ModelContext {
    public func fetchOne<T: UUIDIdentifiedModel>(_ type: T.Type, id: UUID) throws -> T? {
        var descriptor = FetchDescriptor<T>(predicate: T.idPredicate(id))
        descriptor.fetchLimit = 1
        return try fetch(descriptor).first
    }

    /// Inserts a new `T` with `id` if none exists, otherwise updates the existing one. `make()`
    /// only needs to establish identity — `update` is the single place that sets every mutable
    /// field, so create and update apply exactly the same field logic.
    @discardableResult
    public func upsert<T: UUIDIdentifiedModel>(
        _ type: T.Type, id: UUID, make: () -> T, update: (T) -> Void
    ) throws -> T {
        if let existing = try fetchOne(type, id: id) {
            update(existing)
            return existing
        }
        let created = make()
        insert(created)
        update(created)
        return created
    }
}
