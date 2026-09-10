import Foundation

/// A raw GPS coordinate. Deliberately not `CLLocationCoordinate2D` — `PadelCore` stays free of
/// platform frameworks (the same principle as decisions.md #4/#9 for HealthKit), so this and
/// everything built on it is testable with synthetic values, no device required.
public struct GeoPoint: Codable, Hashable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// One of the 6 points a player walks to and marks during court calibration: the 4 corners,
/// plus both net posts (used to locate the net line along the court's length, rather than
/// assuming it sits at an exact midpoint — see `CourtGeometry.netPositionAlongLength`).
///
/// "Near"/"far" and "left"/"right" are arbitrary but consistent for one calibration — they
/// only need to agree with each other, not with any real-world compass direction.
public enum CourtLandmark: String, Codable, Sendable, CaseIterable, Hashable {
    case cornerNearLeft, cornerNearRight, cornerFarLeft, cornerFarRight
    case netLeft, netRight
}

/// The 6 landmark points marked for one court. `CourtGeometry` turns this plus a raw `GeoPoint`
/// sample into a normalized position/zone on the court.
public struct CourtCalibration: Codable, Sendable {
    public var points: [CourtLandmark: GeoPoint]

    public init(points: [CourtLandmark: GeoPoint] = [:]) {
        self.points = points
    }

    /// `true` once all 6 landmarks have been marked.
    public var isComplete: Bool {
        CourtLandmark.allCases.allSatisfy { points[$0] != nil }
    }
}
