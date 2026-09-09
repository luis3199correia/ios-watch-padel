import Foundation
import SwiftUI
import PadelCore

/// Screen 10 — final result. Handles `MatchOutcome.draw` too, since a Mix round reuses this
/// screen shape (decisions.md 8b: a tied round is a valid outcome).
public struct MatchResultScreen: View {
    private let state: MatchState
    private let events: [PointEvent]
    private let teamLabels: TeamLabels
    private let workout: WorkoutMetrics
    private let onDone: () -> Void

    public init(
        state: MatchState, events: [PointEvent], teamLabels: TeamLabels,
        workout: WorkoutMetrics, onDone: @escaping () -> Void
    ) {
        self.state = state
        self.events = events
        self.teamLabels = teamLabels
        self.workout = workout
        self.onDone = onDone
    }

    private var statistics: MatchStatistics { MatchStatistics.compute(from: state, events: events) }

    public var body: some View {
        VStack(spacing: PadelMetrics.spacing12) {
            if let winner = state.phase.winner {
                Image(systemName: "crown.fill").foregroundStyle(PadelColor.yellow)
                Text("\(teamLabels.label(for: winner)) venceram")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(TeamStyle.accent(for: winner))
            } else if state.phase.isDraw {
                Text("Empate").font(.system(size: 16, weight: .heavy)).foregroundStyle(PadelColor.textPrimary)
            }

            HStack(spacing: PadelMetrics.spacing8) {
                ForEach(ScoreFormatter.setScoreSummary(state.sets).components(separatedBy: ", "), id: \.self) { set in
                    PadelPill(set)
                }
            }

            HStack(spacing: PadelMetrics.spacing10) {
                if let duration = statistics.duration {
                    StatTile(value: DurationFormatting.minutes(duration), unit: "min", label: "Duração")
                }
                if let hr = workout.averageHeartRate {
                    StatTile(value: "\(hr)", unit: "bpm", label: "FC média", tint: PadelColor.orange)
                }
                if let kcal = workout.activeCalories {
                    StatTile(value: "\(kcal)", unit: "kcal", label: "Calorias", tint: PadelColor.yellow)
                }
            }

            Button("Concluído", action: onDone).buttonStyle(.padelSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(PadelMetrics.spacing12)
        .background(PadelColor.background)
    }
}

#Preview("A won") {
    MatchResultScreen(
        state: PreviewFixtures.finishedBestOfThree.state, events: PreviewFixtures.finishedBestOfThree.events,
        teamLabels: PreviewFixtures.teamLabels, workout: PreviewFixtures.workoutMetrics, onDone: {}
    )
}

#Preview("Mix round draw") {
    MatchResultScreen(
        state: PreviewFixtures.drawnMixRound.state, events: PreviewFixtures.drawnMixRound.events,
        teamLabels: PreviewFixtures.mixTeamLabels, workout: .empty, onDone: {}
    )
}
