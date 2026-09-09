import PadelCore

/// Flat, `#Predicate`-filterable mirrors of `PadelCore` enum state. `Team` already backs onto
/// `String` ("a"/"b"), so it needs no wrapper here — only the enums with associated values do.

public enum MatchStatus: String, Codable, Sendable, CaseIterable {
    case scheduled, inProgress, finished
}

public enum SessionStatus: String, Codable, Sendable, CaseIterable {
    case scheduled, inProgress, finished
}

public enum MatchFormatKind: String, Codable, Sendable, CaseIterable {
    case sets, proSet, mix
}

extension MatchFormat {
    public var kindRaw: MatchFormatKind {
        switch self {
        case .sets: return .sets
        case .proSet: return .proSet
        case .mix: return .mix
        }
    }

    /// `bestOf` for `.sets`, `targetGames` for `.proSet`, `nil` for `.mix`.
    public var parameter: Int? {
        switch self {
        case .sets(let bestOf): return bestOf
        case .proSet(let targetGames): return targetGames
        case .mix: return nil
        }
    }
}

public enum DeuceRuleKind: String, Codable, Sendable, CaseIterable {
    case classicAdvantage, goldenPoint, starPoint
}

extension DeuceRule {
    public var kindRaw: DeuceRuleKind {
        switch self {
        case .classicAdvantage: return .classicAdvantage
        case .goldenPoint: return .goldenPoint
        case .starPoint: return .starPoint
        }
    }
}

public enum MatchOutcomeKind: String, Codable, Sendable, CaseIterable {
    case win, draw
}

extension MatchOutcome {
    public var kindRaw: MatchOutcomeKind {
        switch self {
        case .win: return .win
        case .draw: return .draw
        }
    }

    public var winnerRaw: String? {
        if case .win(let team) = self { return team.rawValue }
        return nil
    }
}
