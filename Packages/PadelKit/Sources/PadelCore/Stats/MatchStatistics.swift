import Foundation

public struct PointStreak: Sendable, Equatable {
    public let team: Team
    public let count: Int
}

/// Basic derived statistics for a match, computed from its state and event log.
public struct MatchStatistics: Sendable, Equatable {
    public let duration: TimeInterval?
    public let totalPointsA: Int
    public let totalPointsB: Int
    public let longestPointStreak: PointStreak?

    public static func compute(from state: MatchState, events: [PointEvent]) -> MatchStatistics {
        MatchStatistics(
            duration: duration(from: state, events: events),
            totalPointsA: state.pointsWonA,
            totalPointsB: state.pointsWonB,
            longestPointStreak: longestStreak(in: events)
        )
    }

    private static func duration(from state: MatchState, events: [PointEvent]) -> TimeInterval? {
        guard let start = state.startedAt else { return nil }
        if case .finished(_, let endedAt) = state.phase {
            return endedAt.timeIntervalSince(start)
        }
        return events.last.map { $0.timestamp.timeIntervalSince(start) }
    }

    private static func longestStreak(in events: [PointEvent]) -> PointStreak? {
        guard let first = events.first else { return nil }

        var bestTeam = first.team
        var bestCount = 1
        var currentTeam = first.team
        var currentCount = 1

        for event in events.dropFirst() {
            if event.team == currentTeam {
                currentCount += 1
            } else {
                currentTeam = event.team
                currentCount = 1
            }
            if currentCount > bestCount {
                bestCount = currentCount
                bestTeam = currentTeam
            }
        }

        return PointStreak(team: bestTeam, count: bestCount)
    }
}
