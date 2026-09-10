import Foundation
import SwiftData
import PadelCore

/// Repository for `Shot` — one per point (the decisive lance), attached to the `Match` it
/// belongs to.
public enum ShotRepository {

    @discardableResult
    public static func record(
        pointEventID: UUID, zone: CourtZone, rawSample: GeoPoint, strokeType: ShotType?,
        strokeConfidence: Double?, team: Team, for match: Match, at date: Date = .now, in context: ModelContext
    ) -> Shot {
        let shot = Shot(
            pointEventID: pointEventID, zone: zone, rawSample: rawSample,
            strokeType: strokeType, strokeConfidence: strokeConfidence, team: team, recordedAt: date
        )
        context.insert(shot)
        shot.match = match
        return shot
    }

    /// All shots recorded for `match`, in the order they were recorded (oldest first).
    public static func shots(for match: Match) -> [Shot] {
        match.shots.sorted { $0.recordedAt < $1.recordedAt }
    }
}
