import Foundation

/// Returned by `ScoringReducer.apply`, so the caller (and UI) can react to what just happened
/// without having to re-derive it from the before/after states.
public struct ScoringOutcome: Sendable, Equatable {
    public let state: MatchState
    public let didWinGame: Team?
    public let didWinSet: Team?
    public let didWinMatch: Team?
    public let didEnterTieBreak: Bool
    /// `true` when the point was ignored because the match had already finished.
    public let wasRejected: Bool
}

/// Pure functions that turn a `PointEvent` (or a full log of them) into a `MatchState`.
/// This is the single place that understands how a point cascades into a game, set and match
/// win — `MatchEngine` is just a thin, stateful wrapper around it.
public enum ScoringReducer {
    public static func initialState(rules: MatchRules, startedAt: Date? = nil) -> MatchState {
        MatchState(
            rules: rules,
            sets: [SetScore(index: 0, startedAt: startedAt)],
            currentGame: .newGame(startedAt: startedAt),
            servingTeam: .a,
            phase: .notStarted,
            startedAt: startedAt
        )
    }

    public static func apply(_ event: PointEvent, to state: MatchState) -> ScoringOutcome {
        guard !state.phase.isFinished, var currentSet = state.sets.last else {
            return ScoringOutcome(
                state: state, didWinGame: nil, didWinSet: nil, didWinMatch: nil,
                didEnterTieBreak: false, wasRejected: true
            )
        }

        var newState = state
        if case .notStarted = newState.phase { newState.phase = .inProgress }

        let gameOutcome: GameOutcome = currentSet.tieBreak != nil
            ? TieBreakScoring.awardPoint(to: event.team, in: newState.currentGame, targetPoints: newState.rules.tieBreakTargetPoints)
            : GameScoring.awardPoint(to: event.team, in: newState.currentGame, deuceRule: newState.rules.deuceRule)

        switch gameOutcome {
        case .ongoing(let updatedGame):
            newState.currentGame = updatedGame
            if currentSet.tieBreak != nil {
                currentSet.tieBreak = TieBreakScore(
                    pointsA: updatedGame.rawA, pointsB: updatedGame.rawB, startedAt: currentSet.tieBreak?.startedAt
                )
                newState.sets[newState.sets.count - 1] = currentSet
            }
            return ScoringOutcome(
                state: newState, didWinGame: nil, didWinSet: nil, didWinMatch: nil,
                didEnterTieBreak: false, wasRejected: false
            )

        case .won(let gameWinner, let finalGame, let decidedBySuddenDeath):
            currentSet.completedGames.append(CompletedGame(
                index: currentSet.completedGames.count,
                pointsA: finalGame.rawA, pointsB: finalGame.rawB,
                winner: gameWinner, decidedBySuddenDeath: decidedBySuddenDeath,
                servingTeam: newState.servingTeam,
                startedAt: finalGame.startedAt, endedAt: event.timestamp
            ))
            if gameWinner == .a { currentSet.gamesA += 1 } else { currentSet.gamesB += 1 }

            if finalGame.isTieBreak {
                // The deciding point of the tie-break isn't reflected by the `.ongoing` sync
                // below (which only runs for points that don't end the game) — sync it here too,
                // otherwise the winner's recorded tie-break score is off by one.
                currentSet.tieBreak = TieBreakScore(
                    pointsA: finalGame.rawA, pointsB: finalGame.rawB, startedAt: currentSet.tieBreak?.startedAt
                )
            }

            // A tie-break game always finishes the set outright; a regular game is subject to
            // the usual 2-game-margin / tie-break-trigger evaluation.
            let setOutcome: SetOutcome = finalGame.isTieBreak
                ? .won(by: gameWinner, final: currentSet)
                : SetScoring.evaluateAfterRegularGame(currentSet, rules: newState.rules)

            newState.servingTeam = ServeRotation.nextServer(after: newState.servingTeam)

            switch setOutcome {
            case .enteredTieBreak(var updatedSet):
                updatedSet.tieBreak = TieBreakScore(startedAt: event.timestamp)
                newState.sets[newState.sets.count - 1] = updatedSet
                newState.currentGame = .newGame(isTieBreak: true, startedAt: event.timestamp)
                return ScoringOutcome(
                    state: newState, didWinGame: gameWinner, didWinSet: nil, didWinMatch: nil,
                    didEnterTieBreak: true, wasRejected: false
                )

            case .ongoing(let updatedSet):
                newState.sets[newState.sets.count - 1] = updatedSet
                newState.currentGame = .newGame(startedAt: event.timestamp)
                return ScoringOutcome(
                    state: newState, didWinGame: gameWinner, didWinSet: nil, didWinMatch: nil,
                    didEnterTieBreak: false, wasRejected: false
                )

            case .won(let setWinner, var finishedSet):
                finishedSet.winner = setWinner
                finishedSet.endedAt = event.timestamp
                newState.sets[newState.sets.count - 1] = finishedSet

                if let matchWinner = MatchWinnerEvaluator.winner(in: newState.sets, rules: newState.rules) {
                    newState.phase = .finished(outcome: .win(matchWinner), at: event.timestamp)
                    return ScoringOutcome(
                        state: newState, didWinGame: gameWinner, didWinSet: setWinner, didWinMatch: matchWinner,
                        didEnterTieBreak: false, wasRejected: false
                    )
                }

                newState.sets.append(SetScore(index: newState.sets.count, startedAt: event.timestamp))
                newState.currentGame = .newGame(startedAt: event.timestamp)
                return ScoringOutcome(
                    state: newState, didWinGame: gameWinner, didWinSet: setWinner, didWinMatch: nil,
                    didEnterTieBreak: false, wasRejected: false
                )
            }
        }
    }

    /// Reconstructs the match state from scratch by replaying the full event log in order.
    /// This is the canonical definition of "current state" — used both by `MatchEngine` after
    /// an undo, and by anyone rehydrating a match from persisted events.
    public static func replay(_ events: [PointEvent], rules: MatchRules, startedAt: Date? = nil) -> MatchState {
        var state = initialState(rules: rules, startedAt: startedAt)
        for event in events.sorted(by: { $0.sequence < $1.sequence }) {
            state = apply(event, to: state).state
        }
        return state
    }
}
