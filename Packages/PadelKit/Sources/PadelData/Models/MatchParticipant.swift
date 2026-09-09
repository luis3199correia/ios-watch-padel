import Foundation
import SwiftData
import PadelCore

/// One side's slot in a match/session lineup. Always has a `displayName`: for a real `Player`
/// it's a copy of `Player.name` at the time the participant was created (so a later rename
/// doesn't retroactively rewrite old history); for a Mix session's anonymous, rotating
/// opponents (decisions.md 8b) `player` is `nil` and `displayName` is "Adversário 1"/"Adversário
/// 2" — no `Player` record is ever created for them.
///
/// Exactly one of `match`/`session` is non-nil, enforced at the repository layer (same
/// philosophy as decisions.md #6's id uniqueness): a standalone match's 4 participants set
/// `match`; a Mix session's 2 "my team" participants set `session` once and are shared across
/// every round, while each round's 2 opponents set `match`.
@Model
public final class MatchParticipant {
    public var id: UUID = UUID()
    public var teamRaw: String = Team.a.rawValue
    public var displayName: String = ""
    /// 0 or 1 — which of the two slots on the team this is.
    public var position: Int = 0

    public var player: Player?
    public var match: Match?
    public var session: Session?

    public init(id: UUID = UUID(), team: Team, displayName: String, position: Int, player: Player? = nil) {
        self.id = id
        self.teamRaw = team.rawValue
        self.displayName = displayName
        self.position = position
        self.player = player
    }

    public var team: Team { Team(rawValue: teamRaw) ?? .a }
}

extension MatchParticipant: UUIDIdentifiedModel {
    public static func idPredicate(_ id: UUID) -> Predicate<MatchParticipant> {
        #Predicate<MatchParticipant> { $0.id == id }
    }
}

/// Unions a round `Match`'s own participants with its session's shared lineup (if any), so
/// every screen that needs "the 4 people in this round" has one place to ask.
public enum ParticipantRoster {
    public static func resolve(for match: Match) -> [MatchParticipant] {
        var byPosition: [String: MatchParticipant] = [:]
        for participant in match.session?.lineup ?? [] {
            byPosition["\(participant.teamRaw)-\(participant.position)"] = participant
        }
        for participant in match.participants {
            byPosition["\(participant.teamRaw)-\(participant.position)"] = participant
        }
        return byPosition.values.sorted { ($0.teamRaw, $0.position) < ($1.teamRaw, $1.position) }
    }
}
