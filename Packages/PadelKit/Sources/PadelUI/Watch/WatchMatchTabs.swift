import SwiftUI

/// Pages between Controls | Score | Metrics during a live match — the watch convention for
/// swiping between screens while scoring.
public struct WatchMatchTabs: View {
    private let viewModel: LiveScoreViewModel
    private let workout: WorkoutMetrics
    private let onPauseWorkout: () -> Void
    private let onEndMatch: () -> Void

    public init(
        viewModel: LiveScoreViewModel, workout: WorkoutMetrics,
        onPauseWorkout: @escaping () -> Void, onEndMatch: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.workout = workout
        self.onPauseWorkout = onPauseWorkout
        self.onEndMatch = onEndMatch
    }

    public var body: some View {
        TabView {
            MatchControlsScreen(viewModel: viewModel, onPauseWorkout: onPauseWorkout, onEndMatch: onEndMatch)
            LiveScoreScreen(viewModel: viewModel)
            LiveMetricsScreen(metrics: workout)
        }
        .padelPageTabStyle()
    }
}

#Preview {
    WatchMatchTabs(
        viewModel: LiveScoreViewModel(engine: PreviewFixtures.starPointDeuce, teamLabels: PreviewFixtures.teamLabels),
        workout: PreviewFixtures.workoutMetrics, onPauseWorkout: {}, onEndMatch: {}
    )
}
