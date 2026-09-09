import Foundation

/// An upcoming scheduled match/session — shown on the Agenda (iPhone) and Jogos (Watch) screens.
/// Populated from SwiftData in Fase 2 (decisions.md #9).
public struct ScheduledMatch: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let startsAt: Date
    public let location: String
    public let teamLabels: TeamLabels
    public let formatNote: String?

    public init(id: UUID = UUID(), startsAt: Date, location: String, teamLabels: TeamLabels, formatNote: String? = nil) {
        self.id = id
        self.startsAt = startsAt
        self.location = location
        self.teamLabels = teamLabels
        self.formatNote = formatNote
    }
}
