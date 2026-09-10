import Testing
import Foundation
import SwiftData
import PadelCore
@testable import PadelData

@Suite("CourtCalibrationRepository")
@MainActor
struct CourtCalibrationRepositoryTests {

    private func sampleCalibration() -> CourtCalibration {
        CourtCalibration(points: [
            .cornerNearLeft: GeoPoint(latitude: 38.7220, longitude: -9.1390),
            .cornerNearRight: GeoPoint(latitude: 38.7220, longitude: -9.1389),
            .cornerFarLeft: GeoPoint(latitude: 38.7222, longitude: -9.1390),
            .cornerFarRight: GeoPoint(latitude: 38.7222, longitude: -9.1389),
            .netLeft: GeoPoint(latitude: 38.7221, longitude: -9.1390),
            .netRight: GeoPoint(latitude: 38.7221, longitude: -9.1389),
        ])
    }

    @Test("save creates a new calibration record when none exists for the location")
    func saveCreatesRecord() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let record = try CourtCalibrationRepository.save(location: "Padel Norte", calibration: sampleCalibration(), in: context)

        #expect(record.location == "Padel Norte")
        #expect(record.calibration.isComplete)
    }

    @Test("save overwrites the existing calibration instead of creating a duplicate")
    func saveOverwritesExisting() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        try CourtCalibrationRepository.save(location: "Padel Norte", calibration: sampleCalibration(), in: context)

        var updated = sampleCalibration()
        updated.points[.netLeft] = GeoPoint(latitude: 1, longitude: 1)
        try CourtCalibrationRepository.save(location: "Padel Norte", calibration: updated, in: context)

        let fetched = try CourtCalibrationRepository.find(location: "Padel Norte", in: context)
        let found = try #require(fetched)
        #expect(found.calibration.points[.netLeft] == GeoPoint(latitude: 1, longitude: 1))
    }

    @Test("find returns nil for a location that was never calibrated")
    func findReturnsNilForUnknownLocation() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        #expect(try CourtCalibrationRepository.find(location: "Court Central", in: context) == nil)
    }
}
