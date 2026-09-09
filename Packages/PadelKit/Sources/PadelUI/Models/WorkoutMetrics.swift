import Foundation

/// HealthKit workout metrics, as read live or summarized at the end of a match. All fields are
/// optional so the UI degrades gracefully before the app target wires up HealthKit — `PadelUI`
/// never imports HealthKit directly (decisions.md #9, rule 1).
public struct WorkoutMetrics: Equatable, Sendable {
    public let heartRate: Int?
    public let averageHeartRate: Int?
    public let maxHeartRate: Int?
    public let activeCalories: Int?
    public let elapsed: TimeInterval?

    public init(
        heartRate: Int? = nil, averageHeartRate: Int? = nil, maxHeartRate: Int? = nil,
        activeCalories: Int? = nil, elapsed: TimeInterval? = nil
    ) {
        self.heartRate = heartRate
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.activeCalories = activeCalories
        self.elapsed = elapsed
    }

    public static let empty = WorkoutMetrics()
}
