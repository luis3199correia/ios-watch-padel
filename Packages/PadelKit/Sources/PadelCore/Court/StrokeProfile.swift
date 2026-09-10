import Foundation

/// One player's recorded reference swings for one `ShotType`, built from a few repetitions
/// during a "setup" flow (mirrors `CourtCalibration`'s "walk and mark" pattern, but for
/// pancadas instead of court corners). Swing dynamics vary a lot between players (arm length,
/// style, strength, watch orientation), so matching against a player's *own* recordings is far
/// more reliable than one fixed global threshold — see `StrokeClassifier`.
public struct StrokeProfile: Codable, Sendable {
    public var shotType: ShotType
    public var referenceSamples: [MotionSample]

    public init(shotType: ShotType, referenceSamples: [MotionSample]) {
        self.shotType = shotType
        self.referenceSamples = referenceSamples
    }

    /// Distance from `sample` to this profile: the smallest distance to any single reference
    /// sample (nearest-neighbor), not the average — a new swing only needs to closely resemble
    /// ONE recorded rep to count as that stroke type, since a player's own reps naturally vary.
    /// `nil` if no reference samples were recorded.
    func distance(to sample: MotionSample) -> Double? {
        referenceSamples.map { $0.distance(to: sample) }.min()
    }
}
