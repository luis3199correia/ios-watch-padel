import SwiftUI

/// Screen 8 — live HealthKit metrics. Each row falls back to a placeholder before HealthKit
/// is wired up in the app target.
public struct LiveMetricsScreen: View {
    private let metrics: WorkoutMetrics

    public init(metrics: WorkoutMetrics) { self.metrics = metrics }

    public var body: some View {
        VStack(alignment: .leading, spacing: PadelMetrics.spacing12) {
            Text("Ao Vivo").font(PadelFont.sectionLabel).foregroundStyle(PadelColor.textSecondary)
            row(icon: "heart.fill", tint: PadelColor.red, value: metrics.heartRate.map { "\($0)" } ?? "—", unit: "bpm")
            row(icon: "clock", tint: PadelColor.textSecondary, value: metrics.elapsed.map(DurationFormatting.minutesSeconds) ?? "—:—", unit: nil)
            row(icon: "flame.fill", tint: PadelColor.yellow, value: metrics.activeCalories.map { "\($0)" } ?? "—", unit: "kcal")
        }
        .padding(PadelMetrics.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PadelColor.background)
    }

    private func row(icon: String, tint: Color, value: String, unit: String?) -> some View {
        HStack(spacing: PadelMetrics.spacing8) {
            Image(systemName: icon).foregroundStyle(tint)
            (Text(value).font(.system(size: 26, weight: .heavy, design: .rounded))
                + Text(unit.map { " " + $0 } ?? "").font(PadelFont.statUnit))
                .foregroundStyle(PadelColor.textPrimary)
        }
    }
}

#Preview {
    LiveMetricsScreen(metrics: PreviewFixtures.workoutMetrics)
}

#Preview("No HealthKit data yet") {
    LiveMetricsScreen(metrics: .empty)
}
