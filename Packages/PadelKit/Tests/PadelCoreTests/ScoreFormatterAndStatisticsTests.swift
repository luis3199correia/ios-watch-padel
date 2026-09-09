import Foundation
import Testing
@testable import PadelCore

@Suite("ScoreFormatter and MatchStatistics")
struct ScoreFormatterAndStatisticsTests {

    @Test("Advantage is labeled AD for the leading team and 40 for the trailing team")
    func advantageLabels() {
        let advantageA = GameScore(rawA: 4, rawB: 3)
        #expect(ScoreFormatter.gameScoreLabel(for: .a, in: advantageA) == "AD")
        #expect(ScoreFormatter.gameScoreLabel(for: .b, in: advantageA) == "40")
    }

    @Test("Tie-break score label is the raw point count")
    func tieBreakLabel() {
        let tieBreakGame = GameScore(rawA: 5, rawB: 3, isTieBreak: true)
        #expect(ScoreFormatter.gameScoreLabel(for: .a, in: tieBreakGame) == "5")
    }

    @Test("Set summary joins multiple sets with commas")
    func multiSetSummary() {
        let end = Date()
        let sets = [
            SetScore(index: 0, gamesA: 6, gamesB: 4, winner: .a, endedAt: end),
            SetScore(index: 1, gamesA: 4, gamesB: 6, winner: .b, endedAt: end),
            SetScore(index: 2, gamesA: 6, gamesB: 2, winner: .a, endedAt: end),
        ]
        #expect(ScoreFormatter.setScoreSummary(sets) == "6-4, 4-6, 6-2")
    }

    @Test("Set summary includes a drawn mix round (no winner, but it did end)")
    func drawnMixRoundSummary() {
        let set = SetScore(index: 0, gamesA: 4, gamesB: 4, winner: nil, endedAt: Date())
        #expect(ScoreFormatter.setScoreSummary([set]) == "4-4")
    }

    @Test("Set summary excludes a set that hasn't ended yet")
    func unfinishedSetExcludedFromSummary() {
        let set = SetScore(index: 0, gamesA: 3, gamesB: 2)
        #expect(ScoreFormatter.setScoreSummary([set]) == "")
    }

    @Test("MatchStatistics computes duration from start to finish")
    func statisticsDuration() {
        let start = Date(timeIntervalSince1970: 0)
        let end = start.addingTimeInterval(3600)
        let state = MatchState(
            rules: .standardSets,
            sets: [SetScore(index: 0, gamesA: 6, gamesB: 2, winner: .a)],
            currentGame: .newGame(),
            servingTeam: .a,
            phase: .finished(outcome: .win(.a), at: end),
            startedAt: start
        )
        let stats = MatchStatistics.compute(from: state, events: [])
        #expect(stats.duration == 3600)
    }

    @Test("MatchStatistics finds the longest consecutive point streak")
    func statisticsLongestStreak() {
        let events: [PointEvent] = [
            PointEvent(team: .a, sequence: 0),
            PointEvent(team: .a, sequence: 1),
            PointEvent(team: .b, sequence: 2),
            PointEvent(team: .a, sequence: 3),
            PointEvent(team: .a, sequence: 4),
            PointEvent(team: .a, sequence: 5),
        ]
        let state = ScoringReducer.replay(events, rules: .standardSets)
        let stats = MatchStatistics.compute(from: state, events: events)
        #expect(stats.longestPointStreak?.team == .a)
        #expect(stats.longestPointStreak?.count == 3)
    }

    @Test("MatchStatistics returns nil streak for an empty event log")
    func statisticsEmptyLog() {
        let state = ScoringReducer.initialState(rules: .standardSets)
        let stats = MatchStatistics.compute(from: state, events: [])
        #expect(stats.longestPointStreak == nil)
        #expect(stats.totalPointsA == 0 && stats.totalPointsB == 0)
    }

    @Test("MatchStatistics counts breaks of serve (games won while not serving) per team")
    func statisticsBreaksOfServe() {
        let games = [
            CompletedGame(index: 0, pointsA: 4, pointsB: 0, winner: .a, decidedBySuddenDeath: false, servingTeam: .a, startedAt: nil, endedAt: nil), // A holds
            CompletedGame(index: 1, pointsA: 4, pointsB: 2, winner: .a, decidedBySuddenDeath: false, servingTeam: .b, startedAt: nil, endedAt: nil), // A breaks
            CompletedGame(index: 2, pointsA: 1, pointsB: 4, winner: .b, decidedBySuddenDeath: false, servingTeam: .a, startedAt: nil, endedAt: nil), // B breaks
        ]
        let set = SetScore(index: 0, gamesA: 2, gamesB: 1, completedGames: games)
        let state = MatchState(
            rules: .standardSets, sets: [set], currentGame: .newGame(),
            servingTeam: .a, phase: .inProgress, startedAt: nil
        )
        let stats = MatchStatistics.compute(from: state, events: [])
        #expect(stats.breaksOfServeA == 1)
        #expect(stats.breaksOfServeB == 1)
    }
}
