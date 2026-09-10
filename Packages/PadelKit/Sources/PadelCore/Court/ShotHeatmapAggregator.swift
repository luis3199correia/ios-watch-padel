import Foundation

/// How many shots landed in one `CourtZone`.
public struct ZoneCount: Equatable, Sendable {
    public let zone: CourtZone
    public let count: Int

    public init(zone: CourtZone, count: Int) {
        self.zone = zone
        self.count = count
    }
}

/// Aggregates plain `CourtZone` values (already resolved from `Shot`s by the caller — this
/// stays in `PadelCore`, so it never touches SwiftData) into per-zone counts for a heatmap.
public enum ShotHeatmapAggregator {
    /// Only zones that occur at least once are included — no need to enumerate every possible
    /// zone combination up front.
    public static func aggregate(_ zones: [CourtZone]) -> [ZoneCount] {
        var counts: [CourtZone: Int] = [:]
        for zone in zones {
            counts[zone, default: 0] += 1
        }
        return counts.map { ZoneCount(zone: $0.key, count: $0.value) }
    }
}
