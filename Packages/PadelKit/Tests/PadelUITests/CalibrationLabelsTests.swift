import Testing
import PadelCore
@testable import PadelUI

@Suite("CalibrationLabels")
struct CalibrationLabelsTests {

    @Test("Every CourtLandmark has a distinct, non-empty display name")
    func landmarkNamesAreDistinct() {
        let names = CourtLandmark.allCases.map(CalibrationLabels.landmarkName)
        #expect(names.allSatisfy { !$0.isEmpty })
        #expect(Set(names).count == names.count)
    }

    @Test("Every ShotType has a distinct, non-empty display name")
    func shotTypeNamesAreDistinct() {
        let names = ShotType.allCases.map(CalibrationLabels.shotTypeName)
        #expect(names.allSatisfy { !$0.isEmpty })
        #expect(Set(names).count == names.count)
    }

    @Test("Spot-checks known translations")
    func spotChecksKnownTranslations() {
        #expect(CalibrationLabels.shotTypeName(.serve) == "Serviço")
        #expect(CalibrationLabels.shotTypeName(.lob) == "Balão")
        #expect(CalibrationLabels.shotTypeName(.vibora) == "Víbora")
    }
}
