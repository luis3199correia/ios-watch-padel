import Foundation
import SwiftData
import PadelCore

/// Repository for `StrokeProfileRecord` — reads/writes go through `Player.strokeProfiles`
/// directly (never a `FetchDescriptor`) since a player has at most one profile per `ShotType`,
/// already loaded on the relationship — the same pattern `ParticipantRoster` uses.
public enum StrokeProfileRepository {

    /// Creates a new profile for `player`/`shotType`, or overwrites the existing one's samples.
    @discardableResult
    public static func save(shotType: ShotType, referenceSamples: [MotionSample], for player: Player, in context: ModelContext) -> StrokeProfileRecord {
        if let existing = find(shotType: shotType, for: player) {
            existing.referenceSamples = referenceSamples
            return existing
        }
        let record = StrokeProfileRecord(shotType: shotType, referenceSamples: referenceSamples, player: player)
        context.insert(record)
        return record
    }

    public static func find(shotType: ShotType, for player: Player) -> StrokeProfileRecord? {
        player.strokeProfiles.first { $0.shotType == shotType }
    }

    /// All of `player`'s calibrated profiles, ready to pass into `StrokeClassifier.classify`.
    public static func profiles(for player: Player) -> [StrokeProfile] {
        player.strokeProfiles.map(\.profile)
    }
}
