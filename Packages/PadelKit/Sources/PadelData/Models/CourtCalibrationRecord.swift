import Foundation
import SwiftData
import PadelCore

/// A saved `CourtCalibration` for one court, keyed by `location` (the same free-text field used
/// on `Match`/`Session`) — so a player doesn't have to recalibrate every time they play at a
/// court they've already walked and marked.
@Model
public final class CourtCalibrationRecord {
    public var id: UUID = UUID()
    public var location: String = ""
    public var calibrationData: Data = Data()
    public var createdAt: Date = Date.distantPast

    public init(id: UUID = UUID(), location: String, calibration: CourtCalibration, createdAt: Date = .now) {
        self.id = id
        self.location = location
        self.createdAt = createdAt
        self.calibrationData = try! PadelJSON.encode(calibration)
    }

    /// See `Match.rules`'s doc comment for why a decode failure force-unwraps rather than falls
    /// back silently.
    public var calibration: CourtCalibration {
        get { try! PadelJSON.decode(CourtCalibration.self, from: calibrationData) }
        set { calibrationData = try! PadelJSON.encode(newValue) }
    }
}

extension CourtCalibrationRecord: UUIDIdentifiedModel {
    public static func idPredicate(_ id: UUID) -> Predicate<CourtCalibrationRecord> {
        #Predicate<CourtCalibrationRecord> { $0.id == id }
    }
}
