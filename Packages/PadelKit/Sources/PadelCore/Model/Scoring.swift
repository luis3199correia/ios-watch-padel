import Foundation

/// One of the two teams in a doubles padel match.
public enum Team: String, Codable, Sendable, CaseIterable, Hashable {
    case a, b

    public var opponent: Team { self == .a ? .b : .a }
}

/// How a game is decided once both teams have reached 40 (deuce).
public enum DeuceRule: Codable, Hashable, Sendable {
    /// Classic advantage scoring: a team must win by 2 points, with no limit on how many times
    /// the score can return to deuce.
    case classicAdvantage
    /// Sudden death: as soon as the game first reaches 40-40, the next point decides the game.
    case goldenPoint
    /// Advantage is played normally for the first `deuceLimit - 1` times the game reaches 40-40;
    /// the `deuceLimit`-th time the game reaches 40-40, the next point decides the game outright.
    case starPoint(deuceLimit: Int)

    public static let starPointDefault = DeuceRule.starPoint(deuceLimit: 3)
}

/// The shape of a match: either a traditional best-of-N-sets match, or a single continuous
/// "pro-set" played straight to a target number of games.
public enum MatchFormat: Codable, Hashable, Sendable {
    /// Best of `bestOf` sets (1, 3 or 5), each set played to 6 games with a tie-break at 6-6.
    case sets(bestOf: Int)
    /// A single set played straight to `targetGames` (e.g. 9), 2-game margin to win, tie-break
    /// at `targetGames - 1` games each.
    case proSet(targetGames: Int)
}

/// Configurable rules for a match, chosen when the match is created and editable afterwards.
public struct MatchRules: Codable, Hashable, Sendable {
    public var format: MatchFormat
    public var deuceRule: DeuceRule
    public var tieBreakTargetPoints: Int

    public init(format: MatchFormat, deuceRule: DeuceRule, tieBreakTargetPoints: Int = 7) {
        self.format = format
        self.deuceRule = deuceRule
        self.tieBreakTargetPoints = tieBreakTargetPoints
    }

    /// Number of sets a team must win to win the match.
    public var setsNeededToWin: Int {
        switch format {
        case .sets(let bestOf): return bestOf / 2 + 1
        case .proSet: return 1
        }
    }

    /// Number of games needed to win a set outright (with the usual 2-game margin).
    public var gamesToWinSet: Int {
        switch format {
        case .sets: return 6
        case .proSet(let targetGames): return targetGames
        }
    }

    /// Games-apiece score at which a tie-break is triggered.
    public var tieBreakAtGames: Int {
        switch format {
        case .sets: return 6
        case .proSet(let targetGames): return targetGames - 1
        }
    }

    public static let standardSets = MatchRules(format: .sets(bestOf: 3), deuceRule: .classicAdvantage)
    public static let standardProSet = MatchRules(format: .proSet(targetGames: 9), deuceRule: .classicAdvantage)
}

/// A single point awarded to a team. The immutable, ordered log of these events is the source
/// of truth for the whole match — everything else is derived by replaying them.
public struct PointEvent: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let team: Team
    public let timestamp: Date
    public let sequence: Int

    public init(id: UUID = UUID(), team: Team, timestamp: Date = .now, sequence: Int) {
        self.id = id
        self.team = team
        self.timestamp = timestamp
        self.sequence = sequence
    }
}

/// The in-progress (or just-finished) game within the current set. Also used to represent an
/// in-progress tie-break, in which case `isTieBreak` is `true` and `deuceCount` is unused.
public struct GameScore: Codable, Hashable, Sendable {
    public var rawA: Int
    public var rawB: Int
    /// How many times this game has reached a tied score of 40-40 or higher. Unused in tie-breaks.
    public var deuceCount: Int
    public var isTieBreak: Bool
    public var startedAt: Date?

    public init(rawA: Int = 0, rawB: Int = 0, deuceCount: Int = 0, isTieBreak: Bool = false, startedAt: Date? = nil) {
        self.rawA = rawA
        self.rawB = rawB
        self.deuceCount = deuceCount
        self.isTieBreak = isTieBreak
        self.startedAt = startedAt
    }

    public static func newGame(isTieBreak: Bool = false, startedAt: Date? = nil) -> GameScore {
        GameScore(isTieBreak: isTieBreak, startedAt: startedAt)
    }

    public func rawScore(for team: Team) -> Int { team == .a ? rawA : rawB }
}

/// A game that has already been won, kept for the point timeline and statistics.
public struct CompletedGame: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public var index: Int
    public var pointsA: Int
    public var pointsB: Int
    public var winner: Team
    public var decidedBySuddenDeath: Bool
    public var servingTeam: Team
    public var startedAt: Date?
    public var endedAt: Date?

    public init(
        id: UUID = UUID(), index: Int, pointsA: Int, pointsB: Int, winner: Team,
        decidedBySuddenDeath: Bool, servingTeam: Team, startedAt: Date?, endedAt: Date?
    ) {
        self.id = id
        self.index = index
        self.pointsA = pointsA
        self.pointsB = pointsB
        self.winner = winner
        self.decidedBySuddenDeath = decidedBySuddenDeath
        self.servingTeam = servingTeam
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    public func points(for team: Team) -> Int { team == .a ? pointsA : pointsB }
}

/// The score within an in-progress tie-break.
public struct TieBreakScore: Codable, Hashable, Sendable {
    public var pointsA: Int
    public var pointsB: Int
    public var startedAt: Date?

    public init(pointsA: Int = 0, pointsB: Int = 0, startedAt: Date? = nil) {
        self.pointsA = pointsA
        self.pointsB = pointsB
        self.startedAt = startedAt
    }

    public func points(for team: Team) -> Int { team == .a ? pointsA : pointsB }
}

/// One set (or, for `.proSet` matches, the single set that makes up the whole match).
public struct SetScore: Codable, Hashable, Sendable {
    public var index: Int
    public var gamesA: Int
    public var gamesB: Int
    public var tieBreak: TieBreakScore?
    public var completedGames: [CompletedGame]
    public var winner: Team?
    public var startedAt: Date?
    public var endedAt: Date?

    public init(
        index: Int, gamesA: Int = 0, gamesB: Int = 0, tieBreak: TieBreakScore? = nil,
        completedGames: [CompletedGame] = [], winner: Team? = nil, startedAt: Date? = nil, endedAt: Date? = nil
    ) {
        self.index = index
        self.gamesA = gamesA
        self.gamesB = gamesB
        self.tieBreak = tieBreak
        self.completedGames = completedGames
        self.winner = winner
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    public func games(for team: Team) -> Int { team == .a ? gamesA : gamesB }
}

/// Whether the match has started, is in progress, or has finished.
public enum MatchPhase: Codable, Hashable, Sendable {
    case notStarted
    case inProgress
    case finished(winner: Team, at: Date)

    public var isFinished: Bool {
        if case .finished = self { return true }
        return false
    }
}

/// The complete, derived state of a match at some point in time. Always produced by
/// `ScoringReducer` — never constructed or mutated ad hoc by callers.
public struct MatchState: Codable, Hashable, Sendable {
    public var rules: MatchRules
    /// All sets, including the in-progress one (last element) once the match has started.
    public var sets: [SetScore]
    public var currentGame: GameScore
    public var servingTeam: Team
    public var phase: MatchPhase
    public var startedAt: Date?

    public init(
        rules: MatchRules, sets: [SetScore], currentGame: GameScore, servingTeam: Team,
        phase: MatchPhase, startedAt: Date?
    ) {
        self.rules = rules
        self.sets = sets
        self.currentGame = currentGame
        self.servingTeam = servingTeam
        self.phase = phase
        self.startedAt = startedAt
    }

    public var isFinished: Bool { phase.isFinished }

    public func setsWon(by team: Team) -> Int { sets.filter { $0.winner == team }.count }
    public var setsWonA: Int { setsWon(by: .a) }
    public var setsWonB: Int { setsWon(by: .b) }

    public func pointsWon(by team: Team) -> Int {
        sets.reduce(0) { total, set in
            total + set.completedGames.reduce(0) { $0 + $1.points(for: team) }
        }
    }
    public var pointsWonA: Int { pointsWon(by: .a) }
    public var pointsWonB: Int { pointsWon(by: .b) }
}
