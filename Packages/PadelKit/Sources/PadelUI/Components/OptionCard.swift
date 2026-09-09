import SwiftUI

/// A selectable row with a title/subtitle and a checkmark when selected — used both for the
/// deuce-rule/match-format pickers and for confirm-style watch actions ("Terminar Partida").
public struct OptionCard: View {
    private let title: String
    private let subtitle: String?
    private let isSelected: Bool
    private let onTap: () -> Void

    public init(title: String, subtitle: String? = nil, isSelected: Bool, onTap: @escaping () -> Void = {}) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.onTap = onTap
    }

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(PadelFont.cardTitle)
                    .foregroundStyle(isSelected ? PadelColor.mint : PadelColor.textPrimary)
                if let subtitle {
                    Text(subtitle).font(PadelFont.statLabel).foregroundStyle(PadelColor.textSecondary)
                }
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark").foregroundStyle(PadelColor.mint).fontWeight(.heavy)
            }
        }
        .padding(PadelMetrics.spacing12)
        .background(isSelected ? PadelColor.mint.opacity(0.10) : Color.clear)
        .overlay {
            RoundedRectangle(cornerRadius: PadelMetrics.radiusControl, style: .continuous)
                .strokeBorder(isSelected ? PadelColor.mint : PadelColor.border, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: PadelMetrics.radiusControl, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    VStack(spacing: PadelMetrics.spacing8) {
        OptionCard(title: "Terminar Partida", subtitle: "Fecha esta ronda · começa a próxima", isSelected: true)
        OptionCard(title: "Ponto de Ouro", subtitle: "Sudden death imediato a 40-40", isSelected: false)
    }
    .padding()
    .background(PadelColor.background)
}
