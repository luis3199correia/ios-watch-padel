import Foundation
import Observation
import PadelCore

/// Drives the Watch "walk to each corner/net post and mark" court-calibration flow
/// (screens 16/17 in `design/mockups/index.html`). Capturing the real `GeoPoint` from
/// CoreLocation is Fase 3/hardware work — this view model only tracks progress and assembles
/// the `CourtCalibration`, so it's testable with synthetic points.
@Observable
public final class CourtCalibrationViewModel {
    private let landmarks = CourtLandmark.allCases
    public private(set) var calibration = CourtCalibration()
    public private(set) var currentIndex = 0

    public init() {}

    public var totalSteps: Int { landmarks.count }
    public var stepNumber: Int { min(currentIndex + 1, totalSteps) }
    public var isComplete: Bool { currentIndex >= landmarks.count }
    public var currentLandmark: CourtLandmark? { isComplete ? nil : landmarks[currentIndex] }

    /// Marks the current landmark with `point` and advances to the next one. No-op once every
    /// landmark has already been marked.
    public func mark(at point: GeoPoint) {
        guard let landmark = currentLandmark else { return }
        calibration.points[landmark] = point
        currentIndex += 1
    }
}
