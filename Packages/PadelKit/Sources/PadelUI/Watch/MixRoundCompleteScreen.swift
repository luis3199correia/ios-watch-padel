import SwiftUI
import PadelCore

/// Screen 15 — Mix round complete transition. Team `.a` is always "my team" in a Mix round
/// (decisions.md 8b), so the outcome text is phrased from that team's perspective.
public struct MixRoundCompleteScreen: View {
    private let state: MatchState
    private let nextRoundNumber: Int

    public init(state: MatchState, nextRoundNumber: Int) {
        self.state = state
        self.nextRoundNumber = nextRoundNumber
    }

    private var roundLabel: String {
        guard let set = state.sets.last else { return "0-0" }
        return "\(set.gamesA)-\(set.gamesB)"
    }

    private var outcomeText: String {
        if state.phase.winner == .a { return "Venceste a ronda" }
        if state.phase.winner == .b { return "Perdeste a ronda" }
        return "Empate"
    }

    private var scoreTint: Color {
        if state.phase.winner == .a { return PadelColor.blue }
        if state.phase.winner == .b { return PadelColor.orange }
        return PadelColor.textSecondary
    }

    public var body: some View {
        VStack(spacing: PadelMetrics.spacing8) {
            Text("Ronda \(nextRoundNumber - 1) Concluída")
                .font(PadelFont.sectionLabel)
                .foregroundStyle(PadelColor.textSecondary)
            Image(systemName: "checkmark").foregroundStyle(scoreTint)
            Text(roundLabel).font(.system(size: 28, weight: .heavy, design: .rounded)).foregroundStyle(scoreTint)
            Text(outcomeText).font(PadelFont.statLabel).foregroundStyle(PadelColor.textSecondary)

            PadelCard {
                VStack(spacing: 2) {
                    Text("A preparar").font(PadelFont.statLabel).foregroundStyle(PadelColor.textSecondary)
                    Text("Ronda \(nextRoundNumber) →").font(.system(size: 14, weight: .heavy)).foregroundStyle(PadelColor.mint)
                }
            }
        }
        .multilineTextAlignment(.center)
        .padding(PadelMetrics.spacing12)
        .background(PadelColor.background)
    }
}

#Preview("Won") {
    MixRoundCompleteScreen(state: PreviewFixtures.endedMixRoundWonByA.state, nextRoundNumber: 4)
}

#Preview("Draw") {
    MixRoundCompleteScreen(state: PreviewFixtures.drawnMixRound.state, nextRoundNumber: 2)
}
