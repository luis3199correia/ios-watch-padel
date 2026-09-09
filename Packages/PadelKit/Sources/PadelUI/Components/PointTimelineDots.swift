import SwiftUI
import PadelCore

/// A wrapping grid of small dots, one per point, colored by team — with the sudden-death
/// deciding point (if any) highlighted in yellow.
public struct PointTimelineDots: View {
    private let dots: [TimelineDot]
    public init(_ dots: [TimelineDot]) { self.dots = dots }

    public var body: some View {
        let columns = [GridItem(.adaptive(minimum: PadelMetrics.dotSize), spacing: PadelMetrics.spacing4)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: PadelMetrics.spacing4) {
            ForEach(Array(dots.enumerated()), id: \.offset) { _, dot in
                Circle()
                    .fill(dot.isSuddenDeathDecider ? PadelColor.yellow : TeamStyle.accent(for: dot.team))
                    .frame(width: PadelMetrics.dotSize, height: PadelMetrics.dotSize)
            }
        }
        .padding(PadelMetrics.spacing10)
        .background(PadelColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: PadelMetrics.radiusControl, style: .continuous))
    }
}

#Preview {
    PointTimelineDots([
        TimelineDot(team: .a, isSuddenDeathDecider: false),
        TimelineDot(team: .a, isSuddenDeathDecider: false),
        TimelineDot(team: .b, isSuddenDeathDecider: false),
        TimelineDot(team: .b, isSuddenDeathDecider: true),
        TimelineDot(team: .a, isSuddenDeathDecider: false),
    ])
    .padding()
    .background(PadelColor.background)
}
