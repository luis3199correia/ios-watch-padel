import SwiftUI

/// A single "value + unit" stat with a label underneath, e.g. "58min / Duração".
public struct StatTile: View {
    private let value: String
    private let unit: String?
    private let label: String
    private let tint: Color

    public init(value: String, unit: String? = nil, label: String, tint: Color = PadelColor.textPrimary) {
        self.value = value
        self.unit = unit
        self.label = label
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            (Text(value).font(PadelFont.statValue)
                + Text(unit.map { " " + $0 } ?? "").font(PadelFont.statUnit))
                .foregroundStyle(tint)
            Text(label)
                .font(PadelFont.statLabel)
                .foregroundStyle(PadelColor.textSecondary)
        }
    }
}

#Preview {
    HStack(spacing: PadelMetrics.spacing10) {
        PadelCard { StatTile(value: "58", unit: "min", label: "Duração") }
        PadelCard { StatTile(value: "76", unit: "pts", label: "Total de pontos") }
        PadelCard { StatTile(value: "5", unit: "seq.", label: "Melhor sequência", tint: PadelColor.blue) }
    }
    .padding()
    .background(PadelColor.background)
}
