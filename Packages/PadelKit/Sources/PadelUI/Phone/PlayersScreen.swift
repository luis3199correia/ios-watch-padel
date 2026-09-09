import SwiftUI

/// Screen 5 (iPhone) — players list.
public struct PlayersScreen: View {
    private let players: [PlayerRow]
    private let onAdd: () -> Void
    private let onSelect: (PlayerRow) -> Void

    public init(players: [PlayerRow], onAdd: @escaping () -> Void = {}, onSelect: @escaping (PlayerRow) -> Void = { _ in }) {
        self.players = players
        self.onAdd = onAdd
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: PadelMetrics.spacing8) {
                HStack {
                    Text("Jogadores").font(PadelFont.pageTitle).foregroundStyle(PadelColor.textPrimary)
                    Spacer()
                    Button(action: onAdd) { Text("+").font(.system(size: 18, weight: .bold)) }
                        .buttonStyle(.padelPrimary)
                        .frame(width: PadelMetrics.fabSize, height: PadelMetrics.fabSize)
                }

                if players.isEmpty {
                    Text("Ainda não há jogadores. Adiciona o primeiro.")
                        .font(PadelFont.statLabel)
                        .foregroundStyle(PadelColor.textSecondary)
                        .padding(.top, PadelMetrics.spacing18)
                } else {
                    ForEach(players) { player in
                        PadelCard {
                            HStack(spacing: PadelMetrics.spacing10) {
                                Circle()
                                    .fill(player.isMe ? PadelColor.blue : PadelColor.surface2)
                                    .frame(width: PadelMetrics.avatarSize, height: PadelMetrics.avatarSize)
                                    .overlay(Text(player.initials).font(.system(size: 12, weight: .heavy)).foregroundStyle(PadelColor.textPrimary))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(player.name).font(PadelFont.cardTitle).foregroundStyle(PadelColor.textPrimary)
                                    Text(WinRateFormatting.label(matchesPlayed: player.matchesPlayed, wins: player.wins))
                                        .font(PadelFont.statLabel)
                                        .foregroundStyle(PadelColor.textSecondary)
                                }
                                Spacer()
                                if player.isMe {
                                    Image(systemName: "star.fill").foregroundStyle(PadelColor.yellow)
                                } else {
                                    Image(systemName: "chevron.right").foregroundStyle(PadelColor.textSecondary)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { onSelect(player) }
                    }
                }
            }
            .padding()
        }
        .background(PadelColor.background)
    }
}

#Preview {
    PlayersScreen(players: [
        PlayerRow(name: "Luís Correia", initials: "LC", matchesPlayed: 24, wins: 17, isMe: true),
        PlayerRow(name: "Rui Santos", initials: "RS", matchesPlayed: 18, wins: 11),
        PlayerRow(name: "Tiago Marques", initials: "TM", matchesPlayed: 15, wins: 7),
    ])
}

#Preview("Empty") {
    PlayersScreen(players: [])
}
