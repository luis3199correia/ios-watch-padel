import SwiftUI
import PadelCore

/// A padel-court diagram (iPhone), shaded per zone by shot density. Consumes
/// `ShotHeatmapAggregator.aggregate` output — resolving `Shot`s to `CourtZone`s and correlating
/// them with point outcomes is the composition root's job (Fase 3); this view only draws.
public struct CourtHeatmapView: View {
    private let zoneCounts: [ZoneCount]

    public init(zoneCounts: [ZoneCount]) {
        self.zoneCounts = zoneCounts
    }

    public var body: some View {
        Canvas { context, size in
            let rows = CourtHeatmapLayout.rows
            let columns = CourtHeatmapLayout.columns
            let rowHeight = size.height / CGFloat(rows.count)
            let colWidth = size.width / CGFloat(columns.count)

            for (rowIndex, row) in rows.enumerated() {
                for (colIndex, column) in columns.enumerated() {
                    let zone = CourtZone(side: row.side, depth: row.depth, column: column)
                    let rect = CGRect(
                        x: CGFloat(colIndex) * colWidth, y: CGFloat(rowIndex) * rowHeight,
                        width: colWidth, height: rowHeight
                    )
                    let intensity = CourtHeatmapLayout.intensity(for: zone, in: zoneCounts)
                    context.fill(Path(rect), with: .color(fillColor(intensity: intensity)))
                    context.stroke(Path(rect), with: .color(PadelColor.border), lineWidth: 1)
                }
            }

            var netPath = Path()
            netPath.move(to: CGPoint(x: 0, y: size.height / 2))
            netPath.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            context.stroke(netPath, with: .color(PadelColor.textSecondary), lineWidth: 2)
        }
        .aspectRatio(0.5, contentMode: .fit)
        .background(PadelColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: PadelMetrics.radiusCard, style: .continuous))
    }

    private func fillColor(intensity: Double) -> Color {
        intensity > 0 ? PadelColor.mint.opacity(0.15 + intensity * 0.65) : PadelColor.surface2
    }
}

#Preview {
    let counts = [
        ZoneCount(zone: CourtZone(side: .a, depth: .baseline, column: .left), count: 5),
        ZoneCount(zone: CourtZone(side: .a, depth: .net, column: .right), count: 2),
        ZoneCount(zone: CourtZone(side: .b, depth: .net, column: .left), count: 8),
        ZoneCount(zone: CourtZone(side: .b, depth: .baseline, column: .right), count: 1),
    ]
    return CourtHeatmapView(zoneCounts: counts)
        .padding()
        .background(PadelColor.background)
}
