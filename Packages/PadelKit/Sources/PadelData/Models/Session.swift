import Foundation
import SwiftData
import PadelCore

/// A Mix session: several `.mix` rounds (`rounds`, ordered by `Match.roundIndex`) sharing one
/// continuous `HKWorkoutSession` and one "my team" lineup (decisions.md #8b). `targetDuration`/
/// `targetRoundDuration` are visible countdowns only — they never auto-end a round or the
/// session; the user always ends manually (`MatchEngine.endManually()` per round, this entity's
/// own `endedAt` for the whole session).
@Model
public final class Session {
    public var id: UUID = UUID()
    public var statusRaw: String = SessionStatus.scheduled.rawValue
    public var scheduledAt: Date?
    public var startedAt: Date?
    public var endedAt: Date?
    public var location: String = ""
    public var targetDuration: TimeInterval = 0
    public var targetRoundDuration: TimeInterval?

    /// The `.mix` format + chosen `DeuceRule` template every round is created from.
    public var rulesData: Data = Data()

    /// One continuous workout for the whole session — never set on an individual round `Match`.
    public var workoutActivityTypeRaw: UInt?
    public var healthKitWorkoutUUID: UUID?

    // No explicit `inverse:` on either relationship below — `Match`/`MatchParticipant` each have
    // exactly one `Session?`-typed property (`session`), so SwiftData infers the inverse
    // unambiguously by type.
    @Relationship(deleteRule: .cascade)
    public var rounds: [Match] = []
    /// "My team" — 2 real-`Player` participants, created once and shared across every round.
    @Relationship(deleteRule: .cascade)
    public var lineup: [MatchParticipant] = []

    public init(
        id: UUID = UUID(), location: String = "", targetDuration: TimeInterval,
        targetRoundDuration: TimeInterval? = nil, rules: MatchRules, scheduledAt: Date? = nil
    ) {
        self.id = id
        self.location = location
        self.targetDuration = targetDuration
        self.targetRoundDuration = targetRoundDuration
        self.scheduledAt = scheduledAt
        self.statusRaw = SessionStatus.scheduled.rawValue
        self.rulesData = try! PadelJSON.encode(rules)
    }

    public var status: SessionStatus { SessionStatus(rawValue: statusRaw) ?? .scheduled }

    /// See `Match.rules`'s doc comment for why a decode failure force-unwraps rather than falls
    /// back silently.
    public var rules: MatchRules {
        get { try! PadelJSON.decode(MatchRules.self, from: rulesData) }
        set { rulesData = try! PadelJSON.encode(newValue) }
    }
}

extension Session: UUIDIdentifiedModel {
    public static func idPredicate(_ id: UUID) -> Predicate<Session> {
        #Predicate<Session> { $0.id == id }
    }
}
