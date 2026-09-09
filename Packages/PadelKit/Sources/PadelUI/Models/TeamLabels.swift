import PadelCore

/// Display names for both teams — the app target fills this from `Player`/`MatchParticipant`
/// once Fase 2 (SwiftData) exists; for a Mix round, team B is always "Adversário 1 & 2" per
/// decisions.md 8b (anonymous, rotating opponents).
public struct TeamLabels: Equatable, Sendable {
    public let a: String
    public let b: String

    public init(a: String, b: String) {
        self.a = a
        self.b = b
    }

    public func label(for team: Team) -> String { team == .a ? a : b }

    public static let mix = TeamLabels(a: "Eu & Rui", b: "Adversário 1 & 2")
}
