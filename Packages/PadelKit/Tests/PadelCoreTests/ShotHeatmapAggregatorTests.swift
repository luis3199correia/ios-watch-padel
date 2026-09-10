import Foundation
import Testing
@testable import PadelCore

@Suite("ShotHeatmapAggregator")
struct ShotHeatmapAggregatorTests {

    @Test("Counts occurrences of each distinct zone")
    func countsOccurrences() {
        let netLeftA = CourtZone(side: .a, depth: .net, column: .left)
        let baselineRightB = CourtZone(side: .b, depth: .baseline, column: .right)

        let counts = ShotHeatmapAggregator.aggregate([netLeftA, netLeftA, baselineRightB, netLeftA])

        #expect(counts.first { $0.zone == netLeftA }?.count == 3)
        #expect(counts.first { $0.zone == baselineRightB }?.count == 1)
        #expect(counts.count == 2)
    }

    @Test("An empty input produces no zone counts")
    func emptyInputProducesNoCounts() {
        #expect(ShotHeatmapAggregator.aggregate([]).isEmpty)
    }
}
