import PadelCore

/// Portuguese display names for `PadelCore` rule enums. Kept out of `PadelCore` deliberately
/// (decisions.md #9, rule 6) — `ScoreFormatter` is the engine's only presentation-aware file,
/// and it only covers point/set labels, not rule names.
public enum MatchLabels {
    public static func deuceRuleName(_ rule: DeuceRule) -> String {
        switch rule {
        case .classicAdvantage: return "Vantagens Clássicas"
        case .goldenPoint: return "Ponto de Ouro"
        case .starPoint: return "Star Point"
        }
    }

    /// The badge shown on the scoreboard while sudden death is active right now.
    public static func suddenDeathBadge(for rule: DeuceRule) -> String {
        switch rule {
        case .classicAdvantage: return "" // never active under this rule
        case .goldenPoint: return "PONTO DE OURO"
        case .starPoint: return "STAR POINT"
        }
    }

    public static func matchFormatName(_ format: MatchFormat) -> String {
        switch format {
        case .sets(let bestOf): return "Melhor de \(bestOf)"
        case .proSet(let targetGames): return "Pro-set \(targetGames)"
        case .mix: return "Mix"
        }
    }
}
