import SwiftUI

/// Screen 9 — undo / pause / end match. All actions enter as closures; the app target decides
/// what "pause" and "end" actually do (pause the HealthKit workout, stop scoring, etc.).
public struct MatchControlsScreen: View {
    private let viewModel: LiveScoreViewModel
    private let onPauseWorkout: () -> Void
    private let onEndMatch: () -> Void

    public init(viewModel: LiveScoreViewModel, onPauseWorkout: @escaping () -> Void, onEndMatch: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onPauseWorkout = onPauseWorkout
        self.onEndMatch = onEndMatch
    }

    public var body: some View {
        VStack(spacing: PadelMetrics.spacing8) {
            Text("Controlos").font(PadelFont.sectionLabel).foregroundStyle(PadelColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                viewModel.undo()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Desfazer", systemImage: "arrow.uturn.backward")
                        .font(.system(size: 14, weight: .heavy))
                    if let last = viewModel.lastPointDescription {
                        Text("Último: \(last)").font(PadelFont.statLabel).foregroundStyle(PadelColor.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.padelSecondary)
            .disabled(!viewModel.canUndo)

            Button {
                onPauseWorkout()
            } label: {
                Label("Pausar treino", systemImage: "pause.fill").frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.padelSecondary)

            Button("Terminar jogo", action: onEndMatch)
                .buttonStyle(.padelDanger)
        }
        .padding(PadelMetrics.spacing12)
        .background(PadelColor.background)
    }
}

#Preview {
    MatchControlsScreen(
        viewModel: LiveScoreViewModel(engine: PreviewFixtures.starPointDeuce, teamLabels: PreviewFixtures.teamLabels),
        onPauseWorkout: {}, onEndMatch: {}
    )
}
