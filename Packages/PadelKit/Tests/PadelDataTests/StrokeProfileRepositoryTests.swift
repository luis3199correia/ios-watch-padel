import Testing
import Foundation
import SwiftData
import PadelCore
@testable import PadelData

@Suite("StrokeProfileRepository")
@MainActor
struct StrokeProfileRepositoryTests {

    private func sample(_ acceleration: Double) -> MotionSample {
        MotionSample(peakAcceleration: acceleration, peakRotationRate: 5, duration: 0.2, directionDegrees: 0)
    }

    @Test("save creates a new profile for a player/shotType with no existing calibration")
    func saveCreatesProfile() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let player = try PlayerRepository.upsert(name: "Luís", in: context)

        let record = StrokeProfileRepository.save(shotType: .forehand, referenceSamples: [sample(2.5)], for: player, in: context)

        #expect(record.shotType == .forehand)
        #expect(record.referenceSamples == [sample(2.5)])
        #expect(player.strokeProfiles.count == 1)
    }

    @Test("save overwrites the existing profile's samples instead of creating a duplicate")
    func saveOverwritesExistingProfile() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let player = try PlayerRepository.upsert(name: "Luís", in: context)
        StrokeProfileRepository.save(shotType: .forehand, referenceSamples: [sample(2.5)], for: player, in: context)

        StrokeProfileRepository.save(shotType: .forehand, referenceSamples: [sample(9.9)], for: player, in: context)

        #expect(player.strokeProfiles.count == 1)
        #expect(player.strokeProfiles.first?.referenceSamples == [sample(9.9)])
    }

    @Test("find returns nil for a shotType the player hasn't calibrated")
    func findReturnsNilForUncalibratedType() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let player = try PlayerRepository.upsert(name: "Luís", in: context)
        StrokeProfileRepository.save(shotType: .forehand, referenceSamples: [sample(2.5)], for: player, in: context)

        #expect(StrokeProfileRepository.find(shotType: .smash, for: player) == nil)
    }

    @Test("profiles(for:) returns every calibrated StrokeProfile, ready for StrokeClassifier")
    func profilesReturnsAllCalibratedTypes() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let player = try PlayerRepository.upsert(name: "Luís", in: context)
        StrokeProfileRepository.save(shotType: .forehand, referenceSamples: [sample(2.5)], for: player, in: context)
        StrokeProfileRepository.save(shotType: .smash, referenceSamples: [sample(4.5)], for: player, in: context)

        let profiles = StrokeProfileRepository.profiles(for: player)

        #expect(Set(profiles.map(\.shotType)) == [.forehand, .smash])
        let classification = StrokeClassifier.classify(sample(2.5), using: profiles)
        #expect(classification.shotType == .forehand)
        #expect(classification.confidence == 1)
    }
}
