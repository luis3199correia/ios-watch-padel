import Foundation
import Observation
import PadelCore

/// Drives the Watch "record a few reps of each stroke" setup flow (screens 18/19 in
/// `design/mockups/index.html`). Extracting a real `MotionSample` from CoreMotion is
/// Fase 3/hardware work — this view model only tracks progress and assembles the
/// `[StrokeProfile]`, so it's testable with synthetic samples.
@Observable
public final class StrokeCalibrationViewModel {
    /// Repetitions recorded per stroke type before moving on to the next one — matches the
    /// mockup's "Repetição 2 de 3".
    public static let repsPerType = 3

    private let shotTypes = ShotType.allCases
    private var recordedSamples: [ShotType: [MotionSample]] = [:]
    public private(set) var typeIndex = 0
    public private(set) var repIndex = 0

    public init() {}

    public var totalSteps: Int { shotTypes.count }
    public var stepNumber: Int { min(typeIndex + 1, totalSteps) }
    public var isComplete: Bool { typeIndex >= shotTypes.count }
    public var currentShotType: ShotType? { isComplete ? nil : shotTypes[typeIndex] }
    /// 1-based, for display ("Repetição 2 de 3").
    public var currentRepNumber: Int { repIndex + 1 }

    /// Records one repetition of `sample` for the current stroke type, advancing to the next
    /// repetition or, once `repsPerType` is reached, the next stroke type. No-op once complete.
    public func record(_ sample: MotionSample) {
        guard let shotType = currentShotType else { return }
        recordedSamples[shotType, default: []].append(sample)
        repIndex += 1
        if repIndex >= Self.repsPerType {
            repIndex = 0
            typeIndex += 1
        }
    }

    /// The calibrated profiles, one per stroke type with at least one recorded repetition —
    /// pass to `StrokeProfileRepository.save` once the flow finishes.
    public var profiles: [StrokeProfile] {
        recordedSamples.map { StrokeProfile(shotType: $0.key, referenceSamples: $0.value) }
    }
}
