import Testing
import Foundation
@testable import PadelUI

private let utc = TimeZone(identifier: "UTC")!
private var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = utc; return c }
private let ptPT = Locale(identifier: "pt_PT")

private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day))!
}

@Suite("HistoryGrouping")
struct HistoryGroupingTests {

    @Test("Groups entries by month, newest month first")
    func groupsNewestMonthFirst() {
        let entries = [
            HistoryEntry(date: date(2026, 8, 30), location: "A", content: .mixSession(rounds: 1, wins: 1, draws: 0, losses: 0)),
            HistoryEntry(date: date(2026, 9, 4), location: "B", content: .mixSession(rounds: 1, wins: 1, draws: 0, losses: 0)),
        ]
        let groups = HistoryGrouping.grouped(entries, calendar: calendar, locale: ptPT)
        #expect(groups.count == 2)
        #expect(groups[0].title == "Setembro 2026")
        #expect(groups[1].title == "Agosto 2026")
    }

    @Test("Stays newest-first across a year boundary")
    func stableAcrossYearBoundary() {
        let entries = [
            HistoryEntry(date: date(2025, 12, 20), location: "A", content: .mixSession(rounds: 1, wins: 0, draws: 0, losses: 1)),
            HistoryEntry(date: date(2026, 1, 5), location: "B", content: .mixSession(rounds: 1, wins: 1, draws: 0, losses: 0)),
        ]
        let groups = HistoryGrouping.grouped(entries, calendar: calendar, locale: ptPT)
        #expect(groups.map(\.title) == ["Janeiro 2026", "Dezembro 2025"])
    }

    @Test("Entries within a month are newest-first")
    func entriesWithinMonthNewestFirst() {
        let entries = [
            HistoryEntry(date: date(2026, 9, 2), location: "older", content: .mixSession(rounds: 1, wins: 0, draws: 0, losses: 0)),
            HistoryEntry(date: date(2026, 9, 9), location: "newer", content: .mixSession(rounds: 1, wins: 0, draws: 0, losses: 0)),
        ]
        let groups = HistoryGrouping.grouped(entries, calendar: calendar, locale: ptPT)
        #expect(groups.count == 1)
        #expect(groups[0].entries.map(\.location) == ["newer", "older"])
    }

    @Test("Empty input produces no groups")
    func emptyInput() {
        #expect(HistoryGrouping.grouped([], calendar: calendar, locale: ptPT).isEmpty)
    }
}

@Suite("WinRateFormatting")
struct WinRateFormattingTests {
    @Test("Formats matches played and win percentage")
    func formatsWinRate() {
        #expect(WinRateFormatting.label(matchesPlayed: 24, wins: 17) == "24 jogos · 71% vitórias")
    }

    @Test("A player with no matches gets a distinct label, not a division by zero")
    func noMatchesYet() {
        #expect(WinRateFormatting.label(matchesPlayed: 0, wins: 0) == "Sem jogos")
    }
}
