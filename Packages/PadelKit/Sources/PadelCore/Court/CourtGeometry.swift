import Foundation

/// Which end of the court a normalized position falls on, relative to the net.
public enum CourtSide: String, Codable, Sendable, CaseIterable, Hashable {
    case a, b
}

/// How close to the net (vs. the baseline) a normalized position is, on its `CourtSide`.
public enum CourtDepth: String, Codable, Sendable, CaseIterable, Hashable {
    case net, baseline
}

/// Which half (across the court's width) a normalized position falls on.
public enum CourtColumn: String, Codable, Sendable, CaseIterable, Hashable {
    case left, right
}

/// A simplified court zone — 3 independent axes rather than one flat enum, so each can be
/// reasoned about (and extended, e.g. a 3rd depth band later) independently.
public struct CourtZone: Codable, Hashable, Sendable {
    public let side: CourtSide
    public let depth: CourtDepth
    public let column: CourtColumn

    public init(side: CourtSide, depth: CourtDepth, column: CourtColumn) {
        self.side = side
        self.depth = depth
        self.column = column
    }
}

/// Turns raw `GeoPoint` GPS samples into court-relative positions/zones, given a `CourtCalibration`.
///
/// GPS accuracy risk (accepted, per decisions.md-style tradeoff): padel courts are typically
/// enclosed (mesh/glass), which degrades GPS well below its ~3-5m open-sky accuracy, on a court
/// that's only ~20x10m. Every raw `GeoPoint` sample should still be persisted alongside its
/// derived `CourtZone` (see `docs/roadmap.md` Fase 4) so this algorithm — or a manual-correction
/// fallback — can be swapped later without losing already-recorded data.
public enum CourtGeometry {
    private static let earthRadiusMeters = 6_371_000.0

    /// Projects a `GeoPoint` to local planar meters (x = east, y = north) relative to `origin`,
    /// via an equirectangular approximation — accurate enough at court scale (tens of meters).
    static func localMeters(_ point: GeoPoint, relativeTo origin: GeoPoint) -> (x: Double, y: Double) {
        let latRad = origin.latitude * .pi / 180
        let dLat = (point.latitude - origin.latitude) * .pi / 180
        let dLon = (point.longitude - origin.longitude) * .pi / 180
        let y = dLat * earthRadiusMeters
        let x = dLon * earthRadiusMeters * cos(latRad)
        return (x, y)
    }

    /// Normalized court-relative position of `sample`, given a complete `calibration`. `x` runs
    /// across the width (near-left → near-right), `y` along the length (near baseline → far
    /// baseline) — both `nil` if the calibration is incomplete, otherwise clamped to `0...1` so
    /// a sample slightly outside the calibrated rectangle (GPS noise, or a shot played right on
    /// the line) still lands at the edge rather than producing a nonsensical zone.
    ///
    /// Averages the two width edges (near/far) and the two length edges (left/right) into one
    /// basis, rather than using a single pair of corners — real GPS-marked corners never form a
    /// perfect rectangle, and this halves the effect of any one corner's noise.
    public static func normalizedPosition(of sample: GeoPoint, in calibration: CourtCalibration) -> (x: Double, y: Double)? {
        guard calibration.isComplete,
              let nearLeft = calibration.points[.cornerNearLeft],
              let nearRight = calibration.points[.cornerNearRight],
              let farLeft = calibration.points[.cornerFarLeft],
              let farRight = calibration.points[.cornerFarRight]
        else { return nil }

        let origin = nearLeft
        let nr = localMeters(nearRight, relativeTo: origin)
        let fl = localMeters(farLeft, relativeTo: origin)
        let fr = localMeters(farRight, relativeTo: origin)
        let p = localMeters(sample, relativeTo: origin)

        let widthVector = average((nr.x, nr.y), (fr.x - fl.x, fr.y - fl.y))
        let lengthVector = average((fl.x, fl.y), (fr.x - nr.x, fr.y - nr.y))

        let widthLengthSquared = widthVector.0 * widthVector.0 + widthVector.1 * widthVector.1
        let lengthLengthSquared = lengthVector.0 * lengthVector.0 + lengthVector.1 * lengthVector.1
        guard widthLengthSquared > 0, lengthLengthSquared > 0 else { return nil }

        let x = (p.x * widthVector.0 + p.y * widthVector.1) / widthLengthSquared
        let y = (p.x * lengthVector.0 + p.y * lengthVector.1) / lengthLengthSquared
        return (x: clamp(x), y: clamp(y))
    }

    /// Where the net falls along the length axis (`0...1`), averaged from both net posts.
    /// `nil` if the net wasn't calibrated (or the corners weren't, since it needs the same
    /// basis) — callers should fall back to assuming `0.5`.
    public static func netPositionAlongLength(in calibration: CourtCalibration) -> Double? {
        guard let netLeft = calibration.points[.netLeft], let netRight = calibration.points[.netRight] else { return nil }
        let leftY = normalizedPosition(of: netLeft, in: calibration)?.y
        let rightY = normalizedPosition(of: netRight, in: calibration)?.y
        guard let leftY, let rightY else { return nil }
        return (leftY + rightY) / 2
    }

    /// Buckets a normalized position into a `CourtZone`. `netY` is where the net falls along
    /// the length axis (`0...1`); pass `netPositionAlongLength(in:)` when known, or accept the
    /// `0.5` default.
    public static func zone(forX x: Double, y: Double, netY: Double = 0.5) -> CourtZone {
        let side: CourtSide = y < netY ? .a : .b
        let depth: CourtDepth
        switch side {
        case .a: depth = y < netY / 2 ? .baseline : .net
        case .b: depth = y > netY + (1 - netY) / 2 ? .baseline : .net
        }
        let column: CourtColumn = x < 0.5 ? .left : .right
        return CourtZone(side: side, depth: depth, column: column)
    }

    /// Convenience: `normalizedPosition` + `netPositionAlongLength` + `zone(forX:y:netY:)` in
    /// one call — `nil` under the same conditions as `normalizedPosition`.
    public static func zone(of sample: GeoPoint, in calibration: CourtCalibration) -> CourtZone? {
        guard let position = normalizedPosition(of: sample, in: calibration) else { return nil }
        let netY = netPositionAlongLength(in: calibration) ?? 0.5
        return zone(forX: position.x, y: position.y, netY: netY)
    }

    private static func average(_ a: (Double, Double), _ b: (Double, Double)) -> (Double, Double) {
        ((a.0 + b.0) / 2, (a.1 + b.1) / 2)
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
