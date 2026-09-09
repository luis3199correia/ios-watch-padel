import Foundation

public enum DurationFormatting {
    /// "58" for the `StatTile` unit-suffixed display ("58" + "min").
    public static func minutes(_ interval: TimeInterval) -> String {
        String(Int(interval / 60))
    }

    /// "32:14" — elapsed-time watch display.
    public static func minutesSeconds(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// "11:42/15:00" — elapsed vs. target duration, e.g. a Mix round countdown.
    public static func elapsedOverTarget(elapsed: TimeInterval, target: TimeInterval) -> String {
        "\(minutesSeconds(elapsed))/\(minutesSeconds(target))"
    }
}
