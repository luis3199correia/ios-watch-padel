import Testing
import PadelCore
@testable import PadelUI

@Suite("StrokeCalibrationViewModel")
struct StrokeCalibrationViewModelTests {

    private func sample(_ seed: Double) -> MotionSample {
        MotionSample(peakAcceleration: seed, peakRotationRate: seed, duration: 0.2, directionDegrees: seed)
    }

    @Test("Starts on the first shot type, first repetition, not yet complete")
    func startsOnFirstShotType() {
        let vm = StrokeCalibrationViewModel()
        #expect(vm.currentShotType == ShotType.allCases.first)
        #expect(vm.currentRepNumber == 1)
        #expect(vm.stepNumber == 1)
        #expect(vm.totalSteps == ShotType.allCases.count)
        #expect(vm.isComplete == false)
    }

    @Test("Recording fewer than repsPerType stays on the same shot type, advancing the rep count")
    func recordingStaysOnSameTypeUntilRepsComplete() {
        let vm = StrokeCalibrationViewModel()
        let firstType = vm.currentShotType!

        vm.record(sample(1))

        #expect(vm.currentShotType == firstType)
        #expect(vm.currentRepNumber == 2)
        #expect(vm.stepNumber == 1)
    }

    @Test("Recording repsPerType samples advances to the next shot type")
    func recordingAllRepsAdvancesToNextType() {
        let vm = StrokeCalibrationViewModel()
        for i in 0..<StrokeCalibrationViewModel.repsPerType { vm.record(sample(Double(i))) }

        #expect(vm.currentShotType == ShotType.allCases[1])
        #expect(vm.currentRepNumber == 1)
        #expect(vm.stepNumber == 2)
    }

    @Test("Recording every rep for every shot type completes the flow with one profile per type")
    func recordingEverythingCompletes() {
        let vm = StrokeCalibrationViewModel()
        let totalReps = ShotType.allCases.count * StrokeCalibrationViewModel.repsPerType
        for i in 0..<totalReps { vm.record(sample(Double(i))) }

        #expect(vm.isComplete)
        #expect(vm.currentShotType == nil)
        #expect(vm.profiles.count == ShotType.allCases.count)
        #expect(Set(vm.profiles.map(\.shotType)) == Set(ShotType.allCases))
        for profile in vm.profiles {
            #expect(profile.referenceSamples.count == StrokeCalibrationViewModel.repsPerType)
        }
    }

    @Test("Recording after completion is a no-op")
    func recordingAfterCompletionIsNoOp() {
        let vm = StrokeCalibrationViewModel()
        let totalReps = ShotType.allCases.count * StrokeCalibrationViewModel.repsPerType
        for i in 0..<totalReps { vm.record(sample(Double(i))) }
        let profilesBefore = vm.profiles.count

        vm.record(sample(999))

        #expect(vm.isComplete)
        #expect(vm.profiles.count == profilesBefore)
    }
}
