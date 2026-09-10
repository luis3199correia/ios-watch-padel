import Testing
import Foundation
import SwiftData
import PadelCore
@testable import PadelData

@Suite("ShotRepository")
@MainActor
struct ShotRepositoryTests {

    @Test("record attaches a Shot to its match, with the given zone/team/stroke data")
    func recordAttachesShotToMatch() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let match = MatchRepository.scheduleMatch(rules: .standardSets, scheduledAt: .now, location: "", participants: [], in: context)
        let pointEventID = UUID()
        let zone = CourtZone(side: .a, depth: .net, column: .left)
        let sample = GeoPoint(latitude: 38.7, longitude: -9.1)

        let shot = ShotRepository.record(
            pointEventID: pointEventID, zone: zone, rawSample: sample, strokeType: .volley,
            strokeConfidence: 0.8, team: .a, for: match, in: context
        )

        #expect(shot.pointEventID == pointEventID)
        #expect(shot.zone == zone)
        #expect(shot.rawSample == sample)
        #expect(shot.strokeType == .volley)
        #expect(shot.strokeConfidence == 0.8)
        #expect(shot.team == .a)
        #expect(match.shots.count == 1)
    }

    @Test("record accepts no stroke classification, leaving it nil")
    func recordWithoutStrokeClassification() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let match = MatchRepository.scheduleMatch(rules: .standardSets, scheduledAt: .now, location: "", participants: [], in: context)

        let shot = ShotRepository.record(
            pointEventID: UUID(), zone: CourtZone(side: .b, depth: .baseline, column: .right),
            rawSample: GeoPoint(latitude: 0, longitude: 0), strokeType: nil, strokeConfidence: nil, team: .b,
            for: match, in: context
        )

        #expect(shot.strokeType == nil)
        #expect(shot.strokeConfidence == nil)
    }

    @Test("shots(for:) returns them in recorded order")
    func shotsReturnedInRecordedOrder() throws {
        let context = ModelContext(try PadelModelContainer.make(inMemory: true))
        let match = MatchRepository.scheduleMatch(rules: .standardSets, scheduledAt: .now, location: "", participants: [], in: context)
        let zone = CourtZone(side: .a, depth: .net, column: .left)
        let sample = GeoPoint(latitude: 0, longitude: 0)

        let first = ShotRepository.record(
            pointEventID: UUID(), zone: zone, rawSample: sample, strokeType: nil, strokeConfidence: nil,
            team: .a, at: Date(timeIntervalSince1970: 1_000), for: match, in: context
        )
        let second = ShotRepository.record(
            pointEventID: UUID(), zone: zone, rawSample: sample, strokeType: nil, strokeConfidence: nil,
            team: .b, at: Date(timeIntervalSince1970: 2_000), for: match, in: context
        )

        #expect(ShotRepository.shots(for: match).map(\.id) == [first.id, second.id])
    }
}
