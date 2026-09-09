import Foundation
import SwiftUI

/// Screen 1 (iPhone) — agenda: calendar strip + day-grouped upcoming matches. "Iniciar" and "+"
/// are closures — actually creating a match waits for Fase 2 (SwiftData), see decisions.md #9.
public struct AgendaScreen: View {
    private let days: [CalendarStrip.Day]
    private let selectedDay: Date
    private let matches: [ScheduledMatch]
    private let onSelectDay: (Date) -> Void
    private let onAdd: () -> Void
    private let onStart: (ScheduledMatch) -> Void
    private let onSelectMatch: (ScheduledMatch) -> Void

    public init(
        days: [CalendarStrip.Day], selectedDay: Date, matches: [ScheduledMatch],
        onSelectDay: @escaping (Date) -> Void = { _ in }, onAdd: @escaping () -> Void = {},
        onStart: @escaping (ScheduledMatch) -> Void = { _ in }, onSelectMatch: @escaping (ScheduledMatch) -> Void = { _ in }
    ) {
        self.days = days
        self.selectedDay = selectedDay
        self.matches = matches
        self.onSelectDay = onSelectDay
        self.onAdd = onAdd
        self.onStart = onStart
        self.onSelectMatch = onSelectMatch
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PadelMetrics.spacing12) {
                HStack {
                    Text("Agenda").font(PadelFont.pageTitle).foregroundStyle(PadelColor.textPrimary)
                    Spacer()
                    Button(action: onAdd) { Text("+").font(.system(size: 18, weight: .bold)) }
                        .buttonStyle(.padelPrimary)
                        .frame(width: PadelMetrics.fabSize, height: PadelMetrics.fabSize)
                }

                CalendarStrip(days: days, selected: selectedDay, onSelect: onSelectDay)

                if matches.isEmpty {
                    Text("Sem jogos agendados para este dia.")
                        .font(PadelFont.statLabel)
                        .foregroundStyle(PadelColor.textSecondary)
                        .padding(.top, PadelMetrics.spacing18)
                } else {
                    ForEach(matches) { match in
                        PadelCard {
                            HStack {
                                VStack(alignment: .leading, spacing: PadelMetrics.spacing6) {
                                    HStack {
                                        Image(systemName: "clock").foregroundStyle(PadelColor.textSecondary)
                                        Text("\(match.startsAt.formatted(date: .omitted, time: .shortened)) · \(match.location)")
                                            .font(PadelFont.statLabel).foregroundStyle(PadelColor.textSecondary)
                                        Spacer()
                                        if let note = match.formatNote { PadelBadge(note, tint: PadelColor.surface2) }
                                    }
                                    Text(match.teamLabels.a).font(PadelFont.cardTitle).foregroundStyle(PadelColor.textPrimary)
                                    Text(match.teamLabels.b).font(PadelFont.cardTitle).foregroundStyle(PadelColor.textPrimary)
                                }
                                Spacer()
                                Button("Iniciar") { onStart(match) }.buttonStyle(.padelPrimary).fixedSize()
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { onSelectMatch(match) }
                    }
                }
            }
            .padding()
        }
        .background(PadelColor.background)
    }
}

#Preview {
    let today = Date()
    let calendar = Calendar.current
    let days = (0..<7).map { offset -> CalendarStrip.Day in
        let date = calendar.date(byAdding: .day, value: offset - 3, to: today)!
        return CalendarStrip.Day(date: date, weekdayLabel: "Dia", dayNumber: "\(offset + 1)", hasEvent: offset == 2)
    }
    return AgendaScreen(
        days: days, selectedDay: days[3].id,
        matches: [ScheduledMatch(startsAt: today, location: "Court Central", teamLabels: PreviewFixtures.teamLabels, formatNote: "3 SETS")]
    )
}
