import Foundation
import Testing
@testable import PadelCore

@Suite("MotionSample distance")
struct MotionSampleDistanceTests {

    @Test("Distance from a sample to itself is zero")
    func distanceToSelfIsZero() {
        let sample = MotionSample(peakAcceleration: 3, peakRotationRate: 5, duration: 0.2, directionDegrees: 90)
        #expect(sample.distance(to: sample) == 0)
    }

    @Test("Direction distance wraps correctly across the 0/360 boundary")
    func directionWrapsAround() {
        let near0 = MotionSample(peakAcceleration: 1, peakRotationRate: 1, duration: 0.1, directionDegrees: 350)
        let near10 = MotionSample(peakAcceleration: 1, peakRotationRate: 1, duration: 0.1, directionDegrees: 10)
        let farAway = MotionSample(peakAcceleration: 1, peakRotationRate: 1, duration: 0.1, directionDegrees: 190)

        #expect(near0.distance(to: near10) < near0.distance(to: farAway))
    }
}

@Suite("StrokeProfile distance")
struct StrokeProfileDistanceTests {

    @Test("An empty profile has no distance to any sample")
    func emptyProfileHasNoDistance() {
        let profile = StrokeProfile(shotType: .forehand, referenceSamples: [])
        let sample = MotionSample(peakAcceleration: 2, peakRotationRate: 4, duration: 0.2, directionDegrees: 0)
        #expect(profile.distance(to: sample) == nil)
    }

    @Test("Distance is the nearest of several reference samples, not the average")
    func distanceIsNearestNeighbor() {
        let close = MotionSample(peakAcceleration: 2.5, peakRotationRate: 6, duration: 0.25, directionDegrees: 45)
        let far = MotionSample(peakAcceleration: 10, peakRotationRate: 20, duration: 1, directionDegrees: 180)
        let profile = StrokeProfile(shotType: .forehand, referenceSamples: [far, close])
        let sample = MotionSample(peakAcceleration: 2.5, peakRotationRate: 6, duration: 0.25, directionDegrees: 45)

        #expect(profile.distance(to: sample) == 0)
    }
}

@Suite("StrokeClassifier")
struct StrokeClassifierTests {

    @Test("An exact match to a global default profile classifies as that stroke with full confidence")
    func exactMatchToGlobalDefault() {
        for defaultProfile in StrokeClassifier.globalDefaultProfiles {
            let sample = defaultProfile.referenceSamples[0]
            let result = StrokeClassifier.classify(sample, using: [])
            #expect(result.shotType == defaultProfile.shotType)
            #expect(result.confidence == 1)
        }
    }

    @Test("A personal profile overrides the global default for that shot type")
    func personalProfileOverridesGlobalDefault() {
        // A deliberately unusual "forehand" for this player — far from the global forehand
        // default, but exactly matched by their own recorded sample.
        let personalForehand = MotionSample(peakAcceleration: 1.0, peakRotationRate: 1.0, duration: 0.5, directionDegrees: 200)
        let profiles = [StrokeProfile(shotType: .forehand, referenceSamples: [personalForehand])]

        let result = StrokeClassifier.classify(personalForehand, using: profiles)

        #expect(result.shotType == .forehand)
        #expect(result.confidence == 1)
    }

    @Test("A shot type not personally calibrated still falls back to its global default")
    func uncalibratedShotTypeFallsBackToGlobalDefault() {
        let onlyForehand = [StrokeProfile(shotType: .forehand, referenceSamples: [
            MotionSample(peakAcceleration: 9, peakRotationRate: 9, duration: 0.9, directionDegrees: 270),
        ])]
        let smashSample = StrokeClassifier.globalDefaultProfiles.first { $0.shotType == .smash }!.referenceSamples[0]

        let result = StrokeClassifier.classify(smashSample, using: onlyForehand)

        #expect(result.shotType == .smash)
        #expect(result.confidence == 1)
    }

    @Test("A swing far from every profile still returns a guess, with low confidence")
    func distantSwingHasLowConfidence() {
        let bizarre = MotionSample(peakAcceleration: 50, peakRotationRate: 50, duration: 5, directionDegrees: 123)
        let result = StrokeClassifier.classify(bizarre, using: [])
        #expect(result.confidence == 0)
    }
}
