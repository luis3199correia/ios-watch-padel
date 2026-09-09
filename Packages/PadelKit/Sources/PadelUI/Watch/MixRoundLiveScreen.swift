import SwiftUI
import PadelCore

/// Screen 13 — Mix round live score. Reuses `SplitScoreboard`; the header adds the round badge
/// and the (informative-only, never auto-ending) round timer.
public struct MixRoundLiveScreen: View {
    private let viewModel: LiveScoreViewModel
    private let context: MixRoundContext

    public init(viewModel: LiveScoreViewModel, context: MixRoundContext) {
        self.viewModel = viewModel
        self.context = context
    }

    public var body: some View {
        VStack(spacing: PadelMetrics.spacing8) {
            HStack {
                PadelBadge("RONDA \(context.roundNumber)")
                Text(viewModel.currentSetGamesLabel)
                Spacer()
                if let target = context.targetRoundDuration {
                    Text(DurationFormatting.elapsedOverTarget(elapsed: context.elapsed, target: target))
                        .font(PadelFont.statLabel)
                        .foregroundStyle(PadelColor.textSecondary)
                }
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(PadelColor.textPrimary)
            .padding(.horizontal, PadelMetrics.spacing8)

            SplitScoreboard(
                teamAName: viewModel.teamLabels.a,
                teamBName: viewModel.teamLabels.b,
                pointsA: viewModel.pointsLabel(for: .a),
                pointsB: viewModel.pointsLabel(for: .b),
                badge: viewModel.deuceBadge,
                onTap: { team in viewModel.score(team) }
            )
        }
        .background(PadelColor.background)
    }
}

#Preview {
    MixRoundLiveScreen(
        viewModel: LiveScoreViewModel(engine: PreviewFixtures.midRoundMix, teamLabels: PreviewFixtures.mixTeamLabels),
        context: MixRoundContext(roundNumber: 3, elapsed: 11 * 60 + 42, targetRoundDuration: 15 * 60)
    )
}
