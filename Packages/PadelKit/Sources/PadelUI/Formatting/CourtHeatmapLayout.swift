import PadelCore

/// Pure layout/intensity math for the court heatmap diagram (`CourtHeatmapView`) — split out so
/// it's testable without SwiftUI, same separation as `PointTimelineBuilder`/`PointTimelineDots`.
public enum CourtHeatmapLayout {
    /// Rows top-to-bottom, mirroring a real court end-to-end: side `.a` baseline → net → net →
    /// side `.b` baseline (the net sits at the boundary between the 2nd and 3rd row).
    public static let rows: [(side: CourtSide, depth: CourtDepth)] = [
        (.a, .baseline), (.a, .net), (.b, .net), (.b, .baseline),
    ]
    public static let columns: [CourtColumn] = [.left, .right]

    /// Shot count for `zone` in `counts`, `0` if the zone never occurred.
    public static func count(for zone: CourtZone, in counts: [ZoneCount]) -> Int {
        counts.first { $0.zone == zone }?.count ?? 0
    }

    /// `count(for:in:)` normalized against the busiest zone, in `0...1` — `0` for an empty zone
    /// or when every zone is empty.
    public static func intensity(for zone: CourtZone, in counts: [ZoneCount]) -> Double {
        let maxCount = counts.map(\.count).max() ?? 0
        guard maxCount > 0 else { return 0 }
        return Double(count(for: zone, in: counts)) / Double(maxCount)
    }
}
