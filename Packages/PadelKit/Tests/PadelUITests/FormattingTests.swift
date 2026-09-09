import Testing
import PadelCore
@testable import PadelUI

@Suite("MatchLabels")
struct MatchLabelsTests {
    @Test("Deuce rule names in Portuguese")
    func deuceRuleNames() {
        #expect(MatchLabels.deuceRuleName(.classicAdvantage) == "Vantagens Clássicas")
        #expect(MatchLabels.deuceRuleName(.goldenPoint) == "Ponto de Ouro")
        #expect(MatchLabels.deuceRuleName(.starPoint(deuceLimit: 3)) == "Star Point")
    }

    @Test("Sudden-death badge is empty under classic advantage, which never triggers it")
    func suddenDeathBadge() {
        #expect(MatchLabels.suddenDeathBadge(for: .classicAdvantage) == "")
        #expect(MatchLabels.suddenDeathBadge(for: .goldenPoint) == "PONTO DE OURO")
        #expect(MatchLabels.suddenDeathBadge(for: .starPoint(deuceLimit: 3)) == "STAR POINT")
    }

    @Test("Match format names")
    func matchFormatNames() {
        #expect(MatchLabels.matchFormatName(.sets(bestOf: 3)) == "Melhor de 3")
        #expect(MatchLabels.matchFormatName(.proSet(targetGames: 9)) == "Pro-set 9")
        #expect(MatchLabels.matchFormatName(.mix) == "Mix")
    }
}

@Suite("DurationFormatting")
struct DurationFormattingTests {
    @Test("Whole minutes, truncating any remainder")
    func minutes() {
        #expect(DurationFormatting.minutes(58 * 60) == "58")
        #expect(DurationFormatting.minutes(58 * 60 + 59) == "58")
        #expect(DurationFormatting.minutes(0) == "0")
    }

    @Test("mm:ss watch display, zero-padded seconds")
    func minutesSeconds() {
        #expect(DurationFormatting.minutesSeconds(32 * 60 + 14) == "32:14")
        #expect(DurationFormatting.minutesSeconds(5) == "0:05")
    }

    @Test("Elapsed over target duration")
    func elapsedOverTarget() {
        let text = DurationFormatting.elapsedOverTarget(elapsed: 11 * 60 + 42, target: 15 * 60)
        #expect(text == "11:42/15:00")
    }
}
