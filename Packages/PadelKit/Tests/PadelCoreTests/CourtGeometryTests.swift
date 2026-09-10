import Foundation
import Testing
@testable import PadelCore

@Suite("CourtGeometry — GPS calibration and zone mapping")
struct CourtGeometryTests {

    /// Builds an idealized rectangular court (no GPS noise) `widthMeters` × `lengthMeters`,
    /// with the net exactly at the midline — the inverse of `CourtGeometry`'s own
    /// equirectangular approximation, so expectations below can be near-exact.
    private func makeCalibration(widthMeters: Double = 10, lengthMeters: Double = 20) -> CourtCalibration {
        let originLat = 38.7223
        let originLon = -9.1393
        let earthRadiusMeters = 6_371_000.0
        let latPerMeter = 180.0 / (.pi * earthRadiusMeters)
        let lonPerMeter = latPerMeter / cos(originLat * .pi / 180)

        func point(north: Double, east: Double) -> GeoPoint {
            GeoPoint(latitude: originLat + north * latPerMeter, longitude: originLon + east * lonPerMeter)
        }

        return CourtCalibration(points: [
            .cornerNearLeft: point(north: 0, east: 0),
            .cornerNearRight: point(north: 0, east: widthMeters),
            .cornerFarLeft: point(north: lengthMeters, east: 0),
            .cornerFarRight: point(north: lengthMeters, east: widthMeters),
            .netLeft: point(north: lengthMeters / 2, east: 0),
            .netRight: point(north: lengthMeters / 2, east: widthMeters),
        ])
    }

    @Test("An incomplete calibration returns nil")
    func incompleteCalibrationReturnsNil() {
        let calibration = CourtCalibration(points: [.cornerNearLeft: GeoPoint(latitude: 0, longitude: 0)])
        #expect(calibration.isComplete == false)
        #expect(CourtGeometry.normalizedPosition(of: GeoPoint(latitude: 0, longitude: 0), in: calibration) == nil)
    }

    @Test("Each corner maps back to its own (x, y) extreme")
    func cornersMapToExtremes() throws {
        let calibration = makeCalibration()
        let corners: [(CourtLandmark, x: Double, y: Double)] = [
            (.cornerNearLeft, 0, 0), (.cornerNearRight, 1, 0),
            (.cornerFarLeft, 0, 1), (.cornerFarRight, 1, 1),
        ]
        for (landmark, expectedX, expectedY) in corners {
            let sample = try #require(calibration.points[landmark])
            let position = try #require(CourtGeometry.normalizedPosition(of: sample, in: calibration))
            #expect(abs(position.x - expectedX) < 0.001)
            #expect(abs(position.y - expectedY) < 0.001)
        }
    }

    @Test("The court's center maps to (0.5, 0.5)")
    func centerMapsToHalf() throws {
        let calibration = makeCalibration(widthMeters: 10, lengthMeters: 20)
        let center = GeoPoint(
            latitude: (calibration.points[.cornerNearLeft]!.latitude + calibration.points[.cornerFarRight]!.latitude) / 2,
            longitude: (calibration.points[.cornerNearLeft]!.longitude + calibration.points[.cornerFarRight]!.longitude) / 2
        )
        let position = try #require(CourtGeometry.normalizedPosition(of: center, in: calibration))
        #expect(abs(position.x - 0.5) < 0.001)
        #expect(abs(position.y - 0.5) < 0.001)
    }

    @Test("A sample outside the calibrated rectangle is clamped to 0...1")
    func samplesOutsideAreClamped() throws {
        let calibration = makeCalibration()
        let farNorth = GeoPoint(latitude: calibration.points[.cornerFarLeft]!.latitude + 1, longitude: calibration.points[.cornerFarLeft]!.longitude)
        let position = try #require(CourtGeometry.normalizedPosition(of: farNorth, in: calibration))
        #expect(position.y == 1)
        #expect(position.x >= 0 && position.x <= 1)
    }

    @Test("netPositionAlongLength is ~0.5 when the net posts are at the exact midline")
    func netPositionIsMidlineByDefault() throws {
        let calibration = makeCalibration()
        let netY = try #require(CourtGeometry.netPositionAlongLength(in: calibration))
        #expect(abs(netY - 0.5) < 0.001)
    }

    @Test("netPositionAlongLength is nil when the net wasn't calibrated")
    func netPositionIsNilWithoutNetPoints() {
        var points = makeCalibration().points
        points[.netLeft] = nil
        points[.netRight] = nil
        #expect(CourtGeometry.netPositionAlongLength(in: CourtCalibration(points: points)) == nil)
    }

    @Test("zone(forX:y:netY:) buckets each combination of side/depth/column correctly")
    func zoneBucketsCorrectly() {
        #expect(CourtGeometry.zone(forX: 0.1, y: 0.1, netY: 0.5) == CourtZone(side: .a, depth: .baseline, column: .left))
        #expect(CourtGeometry.zone(forX: 0.9, y: 0.4, netY: 0.5) == CourtZone(side: .a, depth: .net, column: .right))
        #expect(CourtGeometry.zone(forX: 0.1, y: 0.6, netY: 0.5) == CourtZone(side: .b, depth: .net, column: .left))
        #expect(CourtGeometry.zone(forX: 0.9, y: 0.9, netY: 0.5) == CourtZone(side: .b, depth: .baseline, column: .right))
    }

    @Test("zone(of:in:) resolves a full court sample end-to-end")
    func zoneOfSampleEndToEnd() throws {
        let calibration = makeCalibration()
        let nearLeftCorner = try #require(calibration.points[.cornerNearLeft])
        let zone = try #require(CourtGeometry.zone(of: nearLeftCorner, in: calibration))
        #expect(zone == CourtZone(side: .a, depth: .baseline, column: .left))
    }
}
