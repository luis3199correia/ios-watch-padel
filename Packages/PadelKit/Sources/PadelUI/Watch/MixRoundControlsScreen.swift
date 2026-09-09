import SwiftUI

/// Screen 14 — Mix round controls. "Terminar Partida" closes just this round (`endRound()`,
/// which is `MatchEngine.endManually()` under the hood); "Terminar Sessão" is the app target's
/// job (stops the single continuous HealthKit workout — decisions.md 8b) so it stays a closure.
public struct MixRoundControlsScreen: View {
    private let viewModel: LiveScoreViewModel
    private let onEndSession: () -> Void

    public init(viewModel: LiveScoreViewModel, onEndSession: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onEndSession = onEndSession
    }

    public var body: some View {
        VStack(spacing: PadelMetrics.spacing8) {
            Text("Ronda · Controlos").font(PadelFont.sectionLabel).foregroundStyle(PadelColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                viewModel.undo()
            } label: {
                Label("Desfazer", systemImage: "arrow.uturn.backward").frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.padelSecondary)
            .disabled(!viewModel.canUndo)

            OptionCard(
                title: "Terminar Partida", subtitle: "Fecha esta ronda · começa a próxima",
                isSelected: true, onTap: { viewModel.endRound() }
            )

            Button {
                onEndSession()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Terminar Sessão").font(.system(size: 14, weight: .heavy))
                    Text("Fecha o Mix todo · para o treino").font(.system(size: 11, weight: .regular))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.padelDanger)
        }
        .padding(PadelMetrics.spacing12)
        .background(PadelColor.background)
    }
}

#Preview {
    MixRoundControlsScreen(
        viewModel: LiveScoreViewModel(engine: PreviewFixtures.midRoundMix, teamLabels: PreviewFixtures.mixTeamLabels),
        onEndSession: {}
    )
}
