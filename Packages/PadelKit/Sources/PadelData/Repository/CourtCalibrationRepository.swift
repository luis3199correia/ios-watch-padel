import Foundation
import SwiftData
import PadelCore

/// Repository for `CourtCalibrationRecord` — one calibration per `location`, reused across
/// every match/session played there.
public enum CourtCalibrationRepository {

    /// Creates a new calibration for `location`, or overwrites the existing one.
    @discardableResult
    public static func save(location: String, calibration: CourtCalibration, in context: ModelContext) throws -> CourtCalibrationRecord {
        if let existing = try find(location: location, in: context) {
            existing.calibration = calibration
            return existing
        }
        let record = CourtCalibrationRecord(location: location, calibration: calibration)
        context.insert(record)
        return record
    }

    public static func find(location: String, in context: ModelContext) throws -> CourtCalibrationRecord? {
        var descriptor = FetchDescriptor<CourtCalibrationRecord>(
            predicate: #Predicate<CourtCalibrationRecord> { $0.location == location }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
