import Foundation

/// Informative-only context for a Mix round in progress. Per decisions.md 8b, the round/session
/// durations are visible timers, never an automatic cutoff — the user always ends a round or
/// session manually.
public struct MixRoundContext: Equatable, Sendable {
    public let roundNumber: Int
    public let elapsed: TimeInterval
    public let targetRoundDuration: TimeInterval?

    public init(roundNumber: Int, elapsed: TimeInterval, targetRoundDuration: TimeInterval? = nil) {
        self.roundNumber = roundNumber
        self.elapsed = elapsed
        self.targetRoundDuration = targetRoundDuration
    }
}
