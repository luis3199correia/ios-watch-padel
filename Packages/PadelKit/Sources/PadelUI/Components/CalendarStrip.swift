import Foundation
import SwiftUI

/// A horizontal week strip, one column per day, with a dot marker for days that have an event
/// and a filled mint circle for the selected day. The caller supplies already-formatted day
/// labels/numbers so this view stays locale-agnostic.
public struct CalendarStrip: View {
    public struct Day: Identifiable, Equatable {
        public let id: Date
        public let weekdayLabel: String
        public let dayNumber: String
        public let hasEvent: Bool

        public init(date: Date, weekdayLabel: String, dayNumber: String, hasEvent: Bool) {
            self.id = date
            self.weekdayLabel = weekdayLabel
            self.dayNumber = dayNumber
            self.hasEvent = hasEvent
        }
    }

    private let days: [Day]
    private let selected: Date
    private let onSelect: (Date) -> Void

    public init(days: [Day], selected: Date, onSelect: @escaping (Date) -> Void) {
        self.days = days
        self.selected = selected
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack {
            ForEach(days) { day in
                let isSelected = day.id == selected
                VStack(spacing: PadelMetrics.spacing6) {
                    Text(day.weekdayLabel).font(.system(size: 12)).foregroundStyle(PadelColor.textSecondary)
                    Text(day.dayNumber)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isSelected ? PadelColor.textOnAccent : PadelColor.textPrimary)
                        .frame(width: 30, height: 30)
                        .background(isSelected ? PadelColor.mint : Color.clear)
                        .clipShape(Circle())
                    Circle()
                        .fill(day.hasEvent ? PadelColor.mint : Color.clear)
                        .frame(width: 4, height: 4)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { onSelect(day.id) }
            }
        }
    }
}

#Preview {
    let today = Date()
    let calendar = Calendar.current
    let days = (0..<7).map { offset -> CalendarStrip.Day in
        let date = calendar.date(byAdding: .day, value: offset, to: today)!
        return CalendarStrip.Day(date: date, weekdayLabel: "Dia", dayNumber: "\(offset + 1)", hasEvent: offset == 2)
    }
    return CalendarStrip(days: days, selected: days[3].id, onSelect: { _ in })
        .padding()
        .background(PadelColor.background)
}
