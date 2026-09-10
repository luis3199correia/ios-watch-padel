import Foundation
import SwiftData
import PadelCore

/// The decisive lance of one point (v1 scope — not the full rally, see `docs/roadmap.md`'s
/// Fase 4): where on the court it happened, what stroke type it was (if classified), and which
/// team hit it. `pointEventID` links back to the `PointEvent` in `Match.events` this shot
/// decided, so a caller can cross-reference zone × stroke type × who won the point.
@Model
public final class Shot {
    public var id: UUID = UUID()
    public var pointEventID: UUID = UUID()
    public var zoneData: Data = Data()
    public var rawSampleData: Data = Data()
    public var strokeTypeRaw: String?
    public var strokeConfidence: Double?
    public var teamRaw: String = Team.a.rawValue
    public var recordedAt: Date = Date.distantPast

    public var match: Match?

    public init(
        id: UUID = UUID(), pointEventID: UUID, zone: CourtZone, rawSample: GeoPoint,
        strokeType: ShotType? = nil, strokeConfidence: Double? = nil, team: Team, recordedAt: Date = .now
    ) {
        self.id = id
        self.pointEventID = pointEventID
        self.strokeTypeRaw = strokeType?.rawValue
        self.strokeConfidence = strokeConfidence
        self.teamRaw = team.rawValue
        self.recordedAt = recordedAt
        self.zoneData = try! PadelJSON.encode(zone)
        self.rawSampleData = try! PadelJSON.encode(rawSample)
    }

    /// See `Match.rules`'s doc comment for why a decode failure force-unwraps rather than falls
    /// back silently.
    public var zone: CourtZone {
        get { try! PadelJSON.decode(CourtZone.self, from: zoneData) }
        set { zoneData = try! PadelJSON.encode(newValue) }
    }

    /// Kept alongside the derived `zone` so the zone-mapping algorithm (or a manual-correction
    /// fallback) can be revised later without losing already-recorded data — see the GPS
    /// accuracy caveat on `CourtGeometry`.
    public var rawSample: GeoPoint {
        get { try! PadelJSON.decode(GeoPoint.self, from: rawSampleData) }
        set { rawSampleData = try! PadelJSON.encode(newValue) }
    }

    public var strokeType: ShotType? {
        get { strokeTypeRaw.flatMap { ShotType(rawValue: $0) } }
        set { strokeTypeRaw = newValue?.rawValue }
    }

    public var team: Team { Team(rawValue: teamRaw) ?? .a }
}

extension Shot: UUIDIdentifiedModel {
    public static func idPredicate(_ id: UUID) -> Predicate<Shot> {
        #Predicate<Shot> { $0.id == id }
    }
}
