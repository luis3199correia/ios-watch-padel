import SwiftUI
import PadelCore

/// Screen 7 — live score. Tapping a scoreboard half scores a point for that team.
public struct LiveScoreScreen: View {
    private let viewModel: LiveScoreViewModel

    public init(viewModel: LiveScoreViewModel) { self.viewModel = viewModel }

    public var body: some View {
        VStack(spacing: PadelMetrics.spacing8) {
            HStack {
                HStack(spacing: 4) {
                    Circle().fill(PadelColor.blue).frame(width: 6, height: 6)
                    Text("\(viewModel.setsWonA) sets")
                    Circle().fill(PadelColor.orange).frame(width: 6, height: 6)
                    Text("\(viewModel.setsWonB)")
                }
                Spacer()
                Text(viewModel.currentSetGamesLabel)
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

#Preview("40-40 Star Point") {
    LiveScoreScreen(viewModel: LiveScoreViewModel(engine: PreviewFixtures.starPointDeuce, teamLabels: PreviewFixtures.teamLabels))
}

#Preview("Mix round") {
    LiveScoreScreen(viewModel: LiveScoreViewModel(engine: PreviewFixtures.midRoundMix, teamLabels: PreviewFixtures.mixTeamLabels))
}
