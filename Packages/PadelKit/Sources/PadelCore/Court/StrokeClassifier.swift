import Foundation

/// The result of classifying one swing.
public struct StrokeClassification: Sendable, Equatable {
    public let shotType: ShotType
    /// `1` for an extremely close match, decaying toward `0` the further the swing was from
    /// any reference sample. Not a statistical probability — just a simple, tunable measure of
    /// "how much to trust this guess".
    public let confidence: Double

    public init(shotType: ShotType, confidence: Double) {
        self.shotType = shotType
        self.confidence = confidence
    }
}

/// Classifies a `MotionSample` into a `ShotType`, by nearest-neighbor distance to `StrokeProfile`s.
public enum StrokeClassifier {
    /// A generic, un-personalized reference profile per `ShotType` — the fallback for a player
    /// who hasn't done the per-stroke setup yet, so the feature works from day one instead of
    /// refusing to classify. These are a starting-point best guess, not tuned from real data
    /// (that needs actual recorded swings from a physical Watch — Fase 4, blocked on Mac/hardware).
    public static let globalDefaultProfiles: [StrokeProfile] = [
        StrokeProfile(shotType: .forehand, referenceSamples: [
            MotionSample(peakAcceleration: 2.5, peakRotationRate: 6, duration: 0.25, directionDegrees: 45),
        ]),
        StrokeProfile(shotType: .backhand, referenceSamples: [
            MotionSample(peakAcceleration: 2.2, peakRotationRate: 5, duration: 0.25, directionDegrees: 315),
        ]),
        StrokeProfile(shotType: .smash, referenceSamples: [
            MotionSample(peakAcceleration: 4.0, peakRotationRate: 9, duration: 0.2, directionDegrees: 0),
        ]),
        StrokeProfile(shotType: .volley, referenceSamples: [
            MotionSample(peakAcceleration: 1.2, peakRotationRate: 3, duration: 0.12, directionDegrees: 30),
        ]),
    ]

    /// Classifies `sample` against `profiles` (one player's calibrated profiles — typically at
    /// most one per `ShotType`, though multiple are accepted), falling back to
    /// `globalDefaultProfiles` for any `ShotType` the player hasn't calibrated yet.
    public static func classify(_ sample: MotionSample, using profiles: [StrokeProfile]) -> StrokeClassification {
        let personalByType = Dictionary(grouping: profiles, by: \.shotType)
        let defaultsByType = Dictionary(grouping: globalDefaultProfiles, by: \.shotType)

        var best: (type: ShotType, distance: Double)?
        for shotType in ShotType.allCases {
            let candidates = personalByType[shotType] ?? defaultsByType[shotType] ?? []
            guard let distance = candidates.compactMap({ $0.distance(to: sample) }).min() else { continue }
            if best == nil || distance < best!.distance {
                best = (shotType, distance)
            }
        }

        guard let best else {
            return StrokeClassification(shotType: .forehand, confidence: 0)
        }
        // Confidence decays linearly from 1 at distance 0 to 0 by distance 3 (three combined
        // normalized-feature-space units away) — a simple, tunable curve, not derived from
        // real-world data yet.
        let confidence = max(0, 1 - best.distance / 3)
        return StrokeClassification(shotType: best.type, confidence: confidence)
    }
}
