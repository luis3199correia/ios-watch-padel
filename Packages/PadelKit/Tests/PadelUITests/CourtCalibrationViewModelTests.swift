import Testing
import PadelCore
@testable import PadelUI

@Suite("CourtCalibrationViewModel")
struct CourtCalibrationViewModelTests {

    @Test("Starts on the first landmark, not yet complete")
    func startsOnFirstLandmark() {
        let vm = CourtCalibrationViewModel()
        #expect(vm.currentLandmark == CourtLandmark.allCases.first)
        #expect(vm.stepNumber == 1)
        #expect(vm.totalSteps == CourtLandmark.allCases.count)
        #expect(vm.isComplete == false)
    }

    @Test("Marking a landmark records the point and advances to the next one")
    func markingAdvances() {
        let vm = CourtCalibrationViewModel()
        let point = GeoPoint(latitude: 38.7, longitude: -9.1)
        let firstLandmark = vm.currentLandmark!

        vm.mark(at: point)

        #expect(vm.calibration.points[firstLandmark] == point)
        #expect(vm.stepNumber == 2)
        #expect(vm.currentLandmark == CourtLandmark.allCases[1])
    }

    @Test("Marking every landmark completes the calibration")
    func markingEveryLandmarkCompletes() {
        let vm = CourtCalibrationViewModel()
        for i in 0..<CourtLandmark.allCases.count {
            vm.mark(at: GeoPoint(latitude: Double(i), longitude: Double(i)))
        }

        #expect(vm.isComplete)
        #expect(vm.currentLandmark == nil)
        #expect(vm.calibration.isComplete)
        #expect(vm.stepNumber == vm.totalSteps)
    }

    @Test("Marking after completion is a no-op")
    func markingAfterCompletionIsNoOp() {
        let vm = CourtCalibrationViewModel()
        for i in 0..<CourtLandmark.allCases.count {
            vm.mark(at: GeoPoint(latitude: Double(i), longitude: Double(i)))
        }
        let calibrationBefore = vm.calibration

        vm.mark(at: GeoPoint(latitude: 99, longitude: 99))

        #expect(vm.calibration.points == calibrationBefore.points)
        #expect(vm.isComplete)
    }
}
