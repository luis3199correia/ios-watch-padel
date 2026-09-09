public enum WinRateFormatting {
    /// "24 jogos · 71% vitórias", or a distinct label when there are no matches yet.
    public static func label(matchesPlayed: Int, wins: Int) -> String {
        guard matchesPlayed > 0 else { return "Sem jogos" }
        let percent = Int((Double(wins) / Double(matchesPlayed) * 100).rounded())
        return "\(matchesPlayed) jogos · \(percent)% vitórias"
    }
}
