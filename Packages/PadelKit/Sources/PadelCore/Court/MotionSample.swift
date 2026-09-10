import Foundation

/// A summarized feature vector for one swing, extracted from the Watch's raw `CMDeviceMotion`
/// during play (that extraction is Fase 4 hardware work — this struct and everything that
/// consumes it are pure and testable with synthetic values).
public struct MotionSample: Codable, Hashable, Sendable {
    /// Peak acceleration magnitude during the swing, in g.
    public var peakAcceleration: Double
    /// Peak rotation rate around the wrist's roll axis during the swing, in rad/s.
    public var peakRotationRate: Double
    /// Duration of the swing gesture, in seconds.
    public var duration: TimeInterval
    /// Dominant swing direction in degrees, device-relative (not compass-relative) — 0 is an
    /// arbitrary reference, increasing clockwise as seen from above the wrist.
    public var directionDegrees: Double

    public init(peakAcceleration: Double, peakRotationRate: Double, duration: TimeInterval, directionDegrees: Double) {
        self.peakAcceleration = peakAcceleration
        self.peakRotationRate = peakRotationRate
        self.duration = duration
        self.directionDegrees = directionDegrees
    }

    /// Rough "typical spread" per feature, used only to bring every feature to a comparable
    /// scale before combining them into one distance — e.g. so `duration` (order of 0.1s)
    /// doesn't get swamped by `peakRotationRate` (order of several rad/s) purely because of
    /// unit choice. Not derived from real data yet (Fase 4/hardware); a reasonable starting
    /// point to be retuned once real swings are available.
    private static let accelerationScale = 2.0
    private static let rotationScale = 4.0
    private static let durationScale = 0.3
    private static let directionScale = 90.0

    /// Distance to `other` in normalized feature space — smaller means more similar swings.
    /// Used by `StrokeProfile`/`StrokeClassifier` for nearest-neighbor stroke matching.
    func distance(to other: MotionSample) -> Double {
        let dAcceleration = (peakAcceleration - other.peakAcceleration) / Self.accelerationScale
        let dRotation = (peakRotationRate - other.peakRotationRate) / Self.rotationScale
        let dDuration = (duration - other.duration) / Self.durationScale
        let dDirection = Self.angularDifference(directionDegrees, other.directionDegrees) / Self.directionScale
        return (dAcceleration * dAcceleration + dRotation * dRotation + dDuration * dDuration + dDirection * dDirection).squareRoot()
    }

    /// The smallest angle (0...180) between two directions in degrees, correctly wrapping
    /// around the 0/360 boundary (e.g. 350° and 10° are 20° apart, not 340°).
    private static func angularDifference(_ a: Double, _ b: Double) -> Double {
        let raw = (a - b).truncatingRemainder(dividingBy: 360)
        let normalized = raw > 180 ? raw - 360 : (raw < -180 ? raw + 360 : raw)
        return abs(normalized)
    }
}
