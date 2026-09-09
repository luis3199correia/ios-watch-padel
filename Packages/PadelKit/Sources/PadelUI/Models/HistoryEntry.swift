import Foundation
import PadelCore

/// A single row in the history list — either a regular match or an aggregated Mix session.
/// Populated from SwiftData entities in Fase 2; deliberately decoupled so `@Model` classes
/// never reach a view body (decisions.md #9).
public struct HistoryEntry: Identifiable, Equatable, Sendable {
    public enum Content: Equatable, Sendable {
        case match(teamLabels: TeamLabels, winner: Team?, setSummary: String, formatNote: String?)
        case mixSession(rounds: Int, wins: Int, draws: Int, losses: Int)
    }

    public let id: UUID
    public let date: Date
    public let location: String
    public let content: Content

    public init(id: UUID = UUID(), date: Date, location: String, content: Content) {
        self.id = id
        self.date = date
        self.location = location
        self.content = content
    }
}
