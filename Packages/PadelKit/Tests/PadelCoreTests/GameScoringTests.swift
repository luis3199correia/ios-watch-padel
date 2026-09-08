import Foundation
import Testing
@testable import PadelCore

@Suite("GameScoring — regular games under each deuce rule")
struct GameScoringTests {

    @Test("Love game: 4 unanswered points wins 4-0")
    func loveGame() {
        var game = GameScore()
        for _ in 0..<3 {
            guard case .ongoing(let updated) = GameScoring.awardPoint(to: .a, in: game, deuceRule: .classicAdvantage) else {
                Issue.record("Expected ongoing game")
                return
            }
            game = updated
        }
        let outcome = GameScoring.awardPoint(to: .a, in: game, deuceRule: .classicAdvantage)
        guard case .won(let winner, let final, let sudden) = outcome else {
            Issue.record("Expected game to be won")
            return
        }
        #expect(winner == .a)
        #expect(final.rawA == 4 && final.rawB == 0)
        #expect(sudden == false)
    }

    @Test("Point labels progress 0 -> 15 -> 30 -> 40", arguments: [0, 1, 2, 3])
    func pointLabels(rawScore: Int) {
        let game = GameScore(rawA: rawScore, rawB: 0)
        let expected = ["0", "15", "30", "40"][rawScore]
        #expect(ScoreFormatter.gameScoreLabel(for: .a, in: game) == expected)
    }

    @Test("Reaching 40-40 from 40-30 registers the first deuce occurrence")
    func firstDeuceIsRecorded() {
        let game = GameScore(rawA: 3, rawB: 2) // 40-30
        let outcome = GameScoring.awardPoint(to: .b, in: game, deuceRule: .classicAdvantage)
        guard case .ongoing(let updated) = outcome else {
            Issue.record("Expected ongoing (deuce), not a win")
            return
        }
        #expect(updated.rawA == 3 && updated.rawB == 3)
        #expect(updated.deuceCount == 1)
    }

    // MARK: - Classic advantage

    @Test("Classic advantage: deuce -> advantage -> broken back -> deuce, indefinitely")
    func classicAdvantageNeverEndsWithoutTwoPointMargin() {
        var game = GameScore(rawA: 3, rawB: 3, deuceCount: 1) // 40-40, 1st deuce

        // A takes advantage.
        guard case .ongoing(let afterAdvantage) = GameScoring.awardPoint(to: .a, in: game, deuceRule: .classicAdvantage) else {
            Issue.record("Advantage should not end the game")
            return
        }
        #expect(afterAdvantage.rawA == 4 && afterAdvantage.rawB == 3)
        game = afterAdvantage

        // B breaks back to deuce again — must NOT win, no matter how many times this repeats.
        guard case .ongoing(let backToDeuce) = GameScoring.awardPoint(to: .b, in: game, deuceRule: .classicAdvantage) else {
            Issue.record("Breaking back should return to deuce, not end the game")
            return
        }
        #expect(backToDeuce.rawA == 4 && backToDeuce.rawB == 4)
        #expect(backToDeuce.deuceCount == 2)
    }

    @Test("Classic advantage: winning two points in a row from deuce wins the game")
    func classicAdvantageWinsWithTwoPointMargin() {
        let deuce = GameScore(rawA: 3, rawB: 3, deuceCount: 1)
        guard case .ongoing(let advantage) = GameScoring.awardPoint(to: .a, in: deuce, deuceRule: .classicAdvantage) else {
            Issue.record("Expected advantage state")
            return
        }
        let outcome = GameScoring.awardPoint(to: .a, in: advantage, deuceRule: .classicAdvantage)
        guard case .won(let winner, _, let sudden) = outcome else {
            Issue.record("Expected game win")
            return
        }
        #expect(winner == .a)
        #expect(sudden == false)
    }

    // MARK: - Golden point

    @Test("Golden point: the very first point at 40-40 decides the game")
    func goldenPointDecidesImmediately() {
        let deuce = GameScore(rawA: 3, rawB: 3, deuceCount: 1)
        let outcome = GameScoring.awardPoint(to: .b, in: deuce, deuceRule: .goldenPoint)
        guard case .won(let winner, let final, let sudden) = outcome else {
            Issue.record("Golden point should decide the game outright")
            return
        }
        #expect(winner == .b)
        #expect(final.rawA == 3 && final.rawB == 4)
        #expect(sudden == true)
    }

    // MARK: - Star point

    @Test("Star point: first two deuces play out as classic advantage")
    func starPointAllowsTwoAdvantageRounds() {
        let rule = DeuceRule.starPoint(deuceLimit: 3)

        // 1st deuce (deuceCount 1): advantage is NOT sudden death.
        let firstDeuce = GameScore(rawA: 3, rawB: 3, deuceCount: 1)
        guard case .ongoing(let advantageA) = GameScoring.awardPoint(to: .a, in: firstDeuce, deuceRule: rule) else {
            Issue.record("First deuce should allow a normal advantage round")
            return
        }
        #expect(advantageA.rawA == 4 && advantageA.rawB == 3)

        // Broken back -> 2nd deuce.
        guard case .ongoing(let secondDeuce) = GameScoring.awardPoint(to: .b, in: advantageA, deuceRule: rule) else {
            Issue.record("Should return to deuce, not end the game")
            return
        }
        #expect(secondDeuce.deuceCount == 2)

        // 2nd deuce still not sudden death.
        guard case .ongoing(let advantageB) = GameScoring.awardPoint(to: .b, in: secondDeuce, deuceRule: rule) else {
            Issue.record("Second deuce should still allow a normal advantage round")
            return
        }
        #expect(advantageB.rawB == 4 && advantageB.rawA == 3)
    }

    @Test("Star point: the third time the game reaches deuce, the next point decides it")
    func starPointDecidesOnThirdDeuce() {
        let rule = DeuceRule.starPoint(deuceLimit: 3)
        let thirdDeuce = GameScore(rawA: 5, rawB: 5, deuceCount: 3)

        let outcome = GameScoring.awardPoint(to: .a, in: thirdDeuce, deuceRule: rule)
        guard case .won(let winner, _, let sudden) = outcome else {
            Issue.record("Third deuce should be sudden death under star point")
            return
        }
        #expect(winner == .a)
        #expect(sudden == true)
    }

    @Test("Star point: does not trigger sudden death before the configured deuce limit")
    func starPointRespectsCustomLimit() {
        let rule = DeuceRule.starPoint(deuceLimit: 5)
        let thirdDeuce = GameScore(rawA: 5, rawB: 5, deuceCount: 3)

        guard case .ongoing = GameScoring.awardPoint(to: .a, in: thirdDeuce, deuceRule: rule) else {
            Issue.record("Sudden death should not trigger before reaching the configured limit")
            return
        }
    }
}
