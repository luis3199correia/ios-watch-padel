import SwiftUI
import PadelCore

/// Screen 12 (iPhone) — Mix session detail. `rounds` are the real, finished `MatchState`s for
/// each round in the session — no separate persistence model needed, since `MatchState` already
/// is the permanent type (decisions.md #9).
public struct MixSessionDetailScreen: View {
    private let dateLocationLabel: String
    private let rounds: [MatchState]
    private let workout: WorkoutMetrics

    public init(dateLocationLabel: String, rounds: [MatchState], workout: WorkoutMetrics) {
        self.dateLocationLabel = dateLocationLabel
        self.rounds = rounds
        self.workout = workout
    }

    private var aggregate: MixSessionAggregate { MixSessionAggregator.aggregate(rounds) }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PadelMetrics.spacing14) {
                Text(dateLocationLabel).font(PadelFont.pageSubtitle).foregroundStyle(PadelColor.textSecondary)

                PadelCard {
                    VStack(spacing: PadelMetrics.spacing10) {
                        HStack {
                            PadelBadge("MIX")
                            Text("\(rounds.count) rondas").font(PadelFont.cardTitle).foregroundStyle(PadelColor.textPrimary)
                        }
                        HStack {
                            StatTile(value: "\(aggregate.wins)", label: "Vitórias", tint: PadelColor.blue)
                            StatTile(value: "\(aggregate.draws)", label: "Empates")
                            StatTile(value: "\(aggregate.losses)", label: "Derrotas", tint: PadelColor.orange)
                            StatTile(value: aggregate.totalGamesLabel, label: "Jogos totais")
                        }
                    }
                }

                Text("Rondas").font(PadelFont.sectionLabel).foregroundStyle(PadelColor.textSecondary)
                ForEach(Array(rounds.enumerated()), id: \.offset) { index, round in
                    roundRow(index: index, round: round)
                }

                Text("Treino (Sessão Completa)").font(PadelFont.sectionLabel).foregroundStyle(PadelColor.textSecondary)
                PadelCard {
                    HStack(spacing: PadelMetrics.spacing12) {
                        if let hr = workout.averageHeartRate, let maxHR = workout.maxHeartRate {
                            StatTile(value: "\(hr)", label: "FC média · máx \(maxHR) bpm", tint: PadelColor.orange)
                        }
                        if let kcal = workout.activeCalories {
                            StatTile(value: "\(kcal)", label: "Calorias ativas", tint: PadelColor.yellow)
                        }
                    }
                }
            }
            .padding()
        }
        .background(PadelColor.background)
    }

    private func roundRow(index: Int, round: MatchState) -> some View {
        let set = round.sets.last
        let label = set.map { "\($0.gamesA)-\($0.gamesB)" } ?? "0-0"
        let tint: Color = round.phase.winner == .a ? PadelColor.blue : (round.phase.winner == .b ? PadelColor.orange : PadelColor.textSecondary)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ronda \(index + 1)").font(PadelFont.cardTitle).foregroundStyle(PadelColor.textPrimary)
                Text("vs Adversário 1 & 2" + (round.phase.isDraw ? " · Empate" : ""))
                    .font(PadelFont.statLabel).foregroundStyle(PadelColor.textSecondary)
            }
            Spacer()
            Text(label).font(.system(size: 16, weight: .heavy)).foregroundStyle(tint)
        }
        .padding(PadelMetrics.spacing14)
        .background(PadelColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: PadelMetrics.radiusControl, style: .continuous))
        .overlay(alignment: .leading) { Rectangle().fill(tint).frame(width: 3) }
    }
}

#Preview {
    MixSessionDetailScreen(
        dateLocationLabel: "Ter, 9 Set 2026 · Padel Norte",
        rounds: [
            PreviewFixtures.endedMixRoundWonByA.state,
            PreviewFixtures.drawnMixRound.state,
        ],
        workout: PreviewFixtures.workoutMetrics
    )
}
