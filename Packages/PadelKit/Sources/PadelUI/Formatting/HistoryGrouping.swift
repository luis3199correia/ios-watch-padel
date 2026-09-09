import Foundation

public enum HistoryGrouping {
    public struct MonthGroup: Identifiable, Equatable, Sendable {
        public let id: String
        public let title: String
        public let entries: [HistoryEntry]
    }

    /// Groups entries by calendar month, newest month first, entries within a month newest first.
    public static func grouped(
        _ entries: [HistoryEntry], calendar: Calendar = .current, locale: Locale = Locale(identifier: "pt_PT")
    ) -> [MonthGroup] {
        let byMonth = Dictionary(grouping: entries) { calendar.dateComponents([.year, .month], from: $0.date) }

        return byMonth.keys
            .sorted { lhs, rhs in
                if lhs.year != rhs.year { return (lhs.year ?? 0) > (rhs.year ?? 0) }
                return (lhs.month ?? 0) > (rhs.month ?? 0)
            }
            .map { key in
                let sortedEntries = (byMonth[key] ?? []).sorted { $0.date > $1.date }
                return MonthGroup(
                    id: "\(key.year ?? 0)-\(key.month ?? 0)",
                    title: monthTitle(for: key, calendar: calendar, locale: locale),
                    entries: sortedEntries
                )
            }
    }

    private static func monthTitle(for components: DateComponents, calendar: Calendar, locale: Locale) -> String {
        guard let date = calendar.date(from: components) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateFormat = "LLLL yyyy"
        let raw = formatter.string(from: date)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }
}
