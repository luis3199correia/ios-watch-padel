import Foundation
import SwiftData
import PadelCore

/// A scheduled, in-progress, or finished match (or, inside a `Session`, one Mix round).
///
/// **In progress**: `rulesData`/`eventsData`/`startedAt` are authoritative; `sets` is empty;
/// `outcomeKindRaw`/`endedAt` are nil. Resuming means `MatchEngine(rules:events:startedAt:)` —
/// i.e. `ScoringReducer.replay` (decisions.md #1).
///
/// **Finished**: `endedAt`, `outcomeKindRaw`/`winnerTeamRaw`, and the denormalized `sets` rows
/// are written once at finish time and read back as static data — no `MatchEngine` is ever
/// rebuilt for a finished match (decisions.md #8b's post-review correction: a manually-ended
/// Mix round's outcome can't be reproduced by replaying the event log alone, since
/// `endManually()` finalizes out-of-band without appending a `PointEvent`).
///
/// `rulesData`/`eventsData` are the source of truth; `formatKindRaw`/`formatParameter`/
/// `deuceRuleKindRaw`/`eventCount` are `#Predicate`-filterable mirrors of `rulesData`/
/// `eventsData`, written only by `rules`/`events`'s setters so they cannot drift.
@Model
public final class Match {
    public var id: UUID = UUID()
    public var statusRaw: String = MatchStatus.scheduled.rawValue
    public var scheduledAt: Date?
    public var startedAt: Date?
    public var endedAt: Date?
    public var location: String = ""
    /// 0 for a standalone match; 0-based round number within a Mix `Session`.
    public var roundIndex: Int = 0

    public var rulesData: Data = Data()
    public var eventsData: Data = Data()
    public var eventCount: Int = 0

    public var formatKindRaw: String = MatchFormatKind.sets.rawValue
    public var formatParameter: Int?
    public var deuceRuleKindRaw: String = DeuceRuleKind.classicAdvantage.rawValue

    public var outcomeKindRaw: String?
    public var winnerTeamRaw: String?

    /// Set only for a standalone match's own `HKWorkoutSession` (`.tennis` per decisions.md #4).
    /// Left `nil` for a Mix round — the workout lives on the owning `Session` instead, since one
    /// continuous workout spans the whole session (decisions.md #8b).
    public var workoutActivityTypeRaw: UInt?
    public var healthKitWorkoutUUID: UUID?

    public var session: Session?
    // No explicit `inverse:` on either relationship below — `MatchSet`/`MatchParticipant` each
    // have exactly one `Match?`-typed property (`match`), so SwiftData infers the inverse
    // unambiguously by type.
    @Relationship(deleteRule: .cascade)
    public var sets: [MatchSet] = []
    @Relationship(deleteRule: .cascade)
    public var participants: [MatchParticipant] = []

    public init(id: UUID = UUID(), location: String = "", roundIndex: Int = 0, rules: MatchRules, scheduledAt: Date? = nil) {
        self.id = id
        self.location = location
        self.roundIndex = roundIndex
        self.scheduledAt = scheduledAt
        self.statusRaw = MatchStatus.scheduled.rawValue

        self.rulesData = try! PadelJSON.encode(rules)
        self.formatKindRaw = rules.format.kindRaw.rawValue
        self.formatParameter = rules.format.parameter
        self.deuceRuleKindRaw = rules.deuceRule.kindRaw.rawValue

        let noEvents: [PointEvent] = []
        self.eventsData = try! PadelJSON.encode(noEvents)
        self.eventCount = 0
    }

    public var status: MatchStatus { MatchStatus(rawValue: statusRaw) ?? .scheduled }

    /// Encoding/decoding failures here mean real data corruption, not a recoverable condition —
    /// this blob is only ever written and read by this same code, so a failure should surface
    /// immediately rather than silently falling back to a default that would misrepresent a
    /// real match (never a silent swallow, per the project's error-handling convention).
    public var rules: MatchRules {
        get { try! PadelJSON.decode(MatchRules.self, from: rulesData) }
        set {
            rulesData = try! PadelJSON.encode(newValue)
            formatKindRaw = newValue.format.kindRaw.rawValue
            formatParameter = newValue.format.parameter
            deuceRuleKindRaw = newValue.deuceRule.kindRaw.rawValue
        }
    }

    public var events: [PointEvent] {
        get { try! PadelJSON.decode([PointEvent].self, from: eventsData) }
        set {
            eventsData = try! PadelJSON.encode(newValue)
            eventCount = newValue.count
        }
    }
}

extension Match: UUIDIdentifiedModel {
    public static func idPredicate(_ id: UUID) -> Predicate<Match> {
        #Predicate<Match> { $0.id == id }
    }
}
