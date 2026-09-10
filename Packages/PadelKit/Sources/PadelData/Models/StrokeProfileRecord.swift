import Foundation
import SwiftData
import PadelCore

/// One player's saved calibration for one `ShotType` (decisions.md-style rationale: swing
/// dynamics vary too much between players for a single global threshold to work well — see
/// `StrokeClassifier` in `PadelCore` and `docs/roadmap.md`'s Fase 4).
@Model
public final class StrokeProfileRecord {
    public var id: UUID = UUID()
    public var shotTypeRaw: String = ShotType.forehand.rawValue
    public var referenceSamplesData: Data = Data()

    public var player: Player?

    public init(id: UUID = UUID(), shotType: ShotType, referenceSamples: [MotionSample], player: Player? = nil) {
        self.id = id
        self.shotTypeRaw = shotType.rawValue
        self.player = player
        self.referenceSamplesData = try! PadelJSON.encode(referenceSamples)
    }

    public var shotType: ShotType { ShotType(rawValue: shotTypeRaw) ?? .forehand }

    /// See `Match.rules`'s doc comment for why a decode failure force-unwraps rather than falls
    /// back silently.
    public var referenceSamples: [MotionSample] {
        get { try! PadelJSON.decode([MotionSample].self, from: referenceSamplesData) }
        set { referenceSamplesData = try! PadelJSON.encode(newValue) }
    }

    /// The `StrokeProfile` `StrokeClassifier.classify(_:using:)` expects.
    public var profile: StrokeProfile {
        StrokeProfile(shotType: shotType, referenceSamples: referenceSamples)
    }
}

extension StrokeProfileRecord: UUIDIdentifiedModel {
    public static func idPredicate(_ id: UUID) -> Predicate<StrokeProfileRecord> {
        #Predicate<StrokeProfileRecord> { $0.id == id }
    }
}
