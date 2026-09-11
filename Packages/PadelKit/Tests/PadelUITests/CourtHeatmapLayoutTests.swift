import Testing
import PadelCore
@testable import PadelUI

@Suite("CourtHeatmapLayout")
struct CourtHeatmapLayoutTests {

    @Test("rows × columns covers exactly the 8 possible court zones, no duplicates")
    func rowsTimesColumnsCoversAllZones() {
        let generated = CourtHeatmapLayout.rows.flatMap { row in
            CourtHeatmapLayout.columns.map { CourtZone(side: row.side, depth: row.depth, column: $0) }
        }
        let allPossible = CourtSide.allCases.flatMap { side in
            CourtDepth.allCases.flatMap { depth in
                CourtColumn.allCases.map { CourtZone(side: side, depth: depth, column: $0) }
            }
        }
        #expect(generated.count == 8)
        #expect(Set(generated) == Set(allPossible))
    }

    @Test("count is 0 for a zone that never occurs")
    func countIsZeroForMissingZone() {
        let zone = CourtZone(side: .a, depth: .baseline, column: .left)
        #expect(CourtHeatmapLayout.count(for: zone, in: []) == 0)
    }

    @Test("count returns the recorded value for a zone that occurs")
    func countReturnsRecordedValue() {
        let zone = CourtZone(side: .a, depth: .baseline, column: .left)
        let counts = [ZoneCount(zone: zone, count: 7)]
        #expect(CourtHeatmapLayout.count(for: zone, in: counts) == 7)
    }

    @Test("intensity is 0 when there is no data at all")
    func intensityIsZeroWithNoData() {
        let zone = CourtZone(side: .a, depth: .baseline, column: .left)
        #expect(CourtHeatmapLayout.intensity(for: zone, in: []) == 0)
    }

    @Test("intensity is 1 for the busiest zone and a fraction for a lighter one")
    func intensityIsNormalizedAgainstBusiestZone() {
        let busy = CourtZone(side: .a, depth: .baseline, column: .left)
        let light = CourtZone(side: .b, depth: .net, column: .right)
        let counts = [ZoneCount(zone: busy, count: 10), ZoneCount(zone: light, count: 5)]

        #expect(CourtHeatmapLayout.intensity(for: busy, in: counts) == 1)
        #expect(CourtHeatmapLayout.intensity(for: light, in: counts) == 0.5)
    }
}
