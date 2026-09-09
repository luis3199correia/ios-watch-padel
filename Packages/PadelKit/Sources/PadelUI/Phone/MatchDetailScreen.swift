import SwiftUI
import PadelCore

/// Screen 4 (iPhone) — finished (or in-progress) match detail: score, point timeline, and
/// HealthKit workout stats.
public struct MatchDetailScreen: View {
    private let state: MatchState
    private let events: [PointEvent]
    private let teamLabels: TeamLabels
    private let dateLocationLabel: String
    private let workout: WorkoutMetrics

    public init(
        state: MatchState, events: [PointEvent], teamLabels: TeamLabels,
        dateLocationLabel: String, workout: WorkoutMetrics
    ) {
        self.state = state
        self.events = events
        self.teamLabels = teamLabels
        self.dateLocationLabel = dateLocationLabel
        self.workout = workout
    }

    private var statistics: MatchStatistics { MatchStatistics.compute(from: state, events: events) }
    private var timeline: [TimelineDot] { PointTimelineBuilder.build(events: events, state: state) }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PadelMetrics.spacing14) {
                Text(dateLocationLabel).font(PadelFont.pageSubtitle).foregroundStyle(PadelColor.textSecondary)

                PadelCard {
                    VStack(spacing: PadelMetrics.spacing8) {
                        scoreRow(team: .a)
                        scoreRow(team: .b)
                        Divider().overlay(PadelColor.border)
                        HStack(spacing: PadelMetrics.spacing8) {
                            ForEach(ScoreFormatter.setScoreSummary(state.sets).components(separatedBy: ", "), id: \.self) { set in
                                PadelPill(set)
                            }
                        }
                    }
                }

                Text("Timeline de Pontos").font(PadelFont.sectionLabel).foregroundStyle(PadelColor.textSecondary)
                PointTimelineDots(timeline)

                statGrid

                Text("Treino (Apple Watch)").font(PadelFont.sectionLabel).foregroundStyle(PadelColor.textSecondary)
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

    private func scoreRow(team: Team) -> some View {
        HStack {
            HStack(spacing: PadelMetrics.spacing6) {
                if state.phase.winner == team { Image(systemName: "crown.fill").foregroundStyle(PadelColor.yellow) }
                Text(teamLabels.label(for: team)).font(PadelFont.cardTitle).foregroundStyle(PadelColor.textPrimary)
            }
            Spacer()
            Text("\(state.setsWon(by: team))").font(PadelFont.statValue).foregroundStyle(PadelColor.textPrimary)
        }
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PadelMetrics.spacing10) {
            if let duration = statistics.duration {
                PadelCard { StatTile(value: DurationFormatting.minutes(duration), unit: "min", label: "Duração") }
            }
            PadelCard { StatTile(value: "\(statistics.totalPointsA + statistics.totalPointsB)", unit: "pts", label: "Total de pontos") }
            if let streak = statistics.longestPointStreak {
                PadelCard { StatTile(value: "\(streak.count)", unit: "seq.", label: "Melhor sequência", tint: TeamStyle.accent(for: streak.team)) }
            }
            PadelCard {
                StatTile(
                    value: "\(statistics.breaksOfServeA)-\(statistics.breaksOfServeB)",
                    label: "Quebras de serviço"
                )
            }
        }
    }
}

#Preview {
    MatchDetailScreen(
        state: PreviewFixtures.finishedBestOfThree.state,
        events: PreviewFixtures.finishedBestOfThree.events,
        teamLabels: PreviewFixtures.teamLabels,
        dateLocationLabel: "Qui, 4 Set 2026 · Court Central",
        workout: PreviewFixtures.workoutMetrics
    )
}
