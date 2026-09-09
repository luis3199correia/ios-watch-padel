import SwiftUI

/// The iPhone app's root tab bar: Agenda | Histórico | Jogadores | Ajustes. "Ajustes" is left
/// to the app target — it's settings/entitlements territory, nothing `PadelUI` owns.
public struct RootTabView<SettingsContent: View>: View {
    private let agenda: AgendaScreen
    private let history: HistoryScreen
    private let players: PlayersScreen
    private let settings: SettingsContent

    public init(agenda: AgendaScreen, history: HistoryScreen, players: PlayersScreen, @ViewBuilder settings: () -> SettingsContent) {
        self.agenda = agenda
        self.history = history
        self.players = players
        self.settings = settings()
    }

    public var body: some View {
        TabView {
            agenda.tabItem { Label("Agenda", systemImage: "calendar") }
            history.tabItem { Label("Histórico", systemImage: "waveform.path.ecg") }
            players.tabItem { Label("Jogadores", systemImage: "person.2") }
            settings.tabItem { Label("Ajustes", systemImage: "gearshape") }
        }
        .tint(PadelColor.mint)
    }
}

#Preview {
    RootTabView(
        agenda: AgendaScreen(days: [], selectedDay: .now, matches: []),
        history: HistoryScreen(entries: []),
        players: PlayersScreen(players: [])
    ) {
        Text("Ajustes").foregroundStyle(PadelColor.textPrimary)
    }
}
