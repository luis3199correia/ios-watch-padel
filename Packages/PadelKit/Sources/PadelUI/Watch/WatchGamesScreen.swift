import SwiftUI

/// Screen 6 — Watch home: upcoming games + quick-start.
public struct WatchGamesScreen: View {
    private let matches: [ScheduledMatch]
    private let onSelect: (ScheduledMatch) -> Void
    private let onQuickGame: () -> Void

    public init(matches: [ScheduledMatch], onSelect: @escaping (ScheduledMatch) -> Void = { _ in }, onQuickGame: @escaping () -> Void = {}) {
        self.matches = matches
        self.onSelect = onSelect
        self.onQuickGame = onQuickGame
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: PadelMetrics.spacing8) {
                Text("Jogos").font(PadelFont.pageTitleCompact).foregroundStyle(PadelColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(matches) { match in
                    PadelCard {
                        VStack(alignment: .leading, spacing: PadelMetrics.spacing6) {
                            Text(match.startsAt.formatted(date: .omitted, time: .shortened) + " · " + match.location)
                                .font(PadelFont.statLabel).foregroundStyle(PadelColor.textSecondary)
                            Text(match.teamLabels.a).font(.system(size: 14, weight: .heavy)).foregroundStyle(PadelColor.textPrimary)
                            Text(match.teamLabels.b).font(.system(size: 14, weight: .heavy)).foregroundStyle(PadelColor.textPrimary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(match) }
                }

                Button("+ Jogo Rápido", action: onQuickGame).buttonStyle(.padelPrimary)
            }
            .padding(PadelMetrics.spacing12)
        }
        .background(PadelColor.background)
    }
}

#Preview {
    WatchGamesScreen(matches: [
        ScheduledMatch(startsAt: .now, location: "Court Central", teamLabels: PreviewFixtures.teamLabels),
    ])
}
