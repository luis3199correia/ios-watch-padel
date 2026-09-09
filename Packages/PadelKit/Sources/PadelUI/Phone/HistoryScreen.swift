import SwiftUI
import PadelCore

/// Screen 3 (iPhone) — history, grouped by month.
public struct HistoryScreen: View {
    private let entries: [HistoryEntry]
    private let onSelect: (HistoryEntry) -> Void

    public init(entries: [HistoryEntry], onSelect: @escaping (HistoryEntry) -> Void = { _ in }) {
        self.entries = entries
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PadelMetrics.spacing8) {
                Text("Histórico").font(PadelFont.pageTitle).foregroundStyle(PadelColor.textPrimary)

                if entries.isEmpty {
                    Text("Ainda não há jogos registados.")
                        .font(PadelFont.statLabel)
                        .foregroundStyle(PadelColor.textSecondary)
                        .padding(.top, PadelMetrics.spacing18)
                } else {
                    ForEach(HistoryGrouping.grouped(entries)) { group in
                        Text(group.title.uppercased()).font(PadelFont.sectionLabel).foregroundStyle(PadelColor.textSecondary)
                        ForEach(group.entries) { entry in
                            row(for: entry).contentShape(Rectangle()).onTapGesture { onSelect(entry) }
                        }
                    }
                }
            }
            .padding()
        }
        .background(PadelColor.background)
    }

    @ViewBuilder
    private func row(for entry: HistoryEntry) -> some View {
        switch entry.content {
        case .match(let teamLabels, let winner, let setSummary, let formatNote):
            PadelCard {
                VStack(alignment: .leading, spacing: PadelMetrics.spacing6) {
                    Text(entry.location).font(PadelFont.statLabel).foregroundStyle(PadelColor.textSecondary)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            teamLine(name: teamLabels.a, team: .a, isWinner: winner == .a)
                            teamLine(name: teamLabels.b, team: .b, isWinner: winner == .b)
                        }
                        Spacer()
                        Text(setSummary).font(PadelFont.cardTitle).foregroundStyle(PadelColor.textPrimary)
                    }
                    if let formatNote {
                        Text(formatNote).font(PadelFont.statLabel).foregroundStyle(PadelColor.textSecondary)
                    }
                }
            }
        case .mixSession(let rounds, let wins, let draws, let losses):
            PadelCard {
                VStack(alignment: .leading, spacing: PadelMetrics.spacing6) {
                    HStack { PadelBadge("MIX"); Text(entry.location).font(PadelFont.statLabel).foregroundStyle(PadelColor.textSecondary) }
                    HStack {
                        Text("\(rounds) rondas").font(PadelFont.cardTitle).foregroundStyle(PadelColor.textPrimary)
                        Spacer()
                        Text("\(wins)V · \(draws)E · \(losses)D").font(PadelFont.cardTitle).foregroundStyle(PadelColor.textPrimary)
                    }
                }
            }
        }
    }

    private func teamLine(name: String, team: Team, isWinner: Bool) -> some View {
        Text("● \(name)")
            .font(.system(size: 13, weight: isWinner ? .heavy : .regular))
            .foregroundStyle(TeamStyle.accent(for: team))
    }
}

#Preview {
    HistoryScreen(entries: [
        HistoryEntry(date: .now, location: "Padel Norte", content: .mixSession(rounds: 5, wins: 3, draws: 1, losses: 1)),
        HistoryEntry(date: .now.addingTimeInterval(-86400 * 5), location: "Court Central", content: .match(
            teamLabels: TeamLabels(a: "Luís & Rui", b: "Tiago & André"), winner: .a, setSummary: "6-4, 7-6", formatNote: nil
        )),
        HistoryEntry(date: .now.addingTimeInterval(-86400 * 40), location: "Court Central", content: .match(
            teamLabels: TeamLabels(a: "Luís & Rui", b: "Pedro & João"), winner: .a, setSummary: "9-5", formatNote: "Pro-set · Ponto de Ouro"
        )),
    ])
}

#Preview("Empty") {
    HistoryScreen(entries: [])
}
