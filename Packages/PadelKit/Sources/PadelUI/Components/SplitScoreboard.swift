import SwiftUI
import PadelCore

/// A small pill announcing sudden-death is active right now, e.g. "STAR POINT" / "PONTO DE OURO".
/// Dark text on a bright yellow fill — no contrast fix needed here, unlike the rest of the UI.
public struct DeuceBadge: View {
    private let text: String
    public init(_ text: String) { self.text = text }

    public var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(PadelColor.textOnAccent)
            .padding(.horizontal, PadelMetrics.spacing12)
            .padding(.vertical, 5)
            .background(PadelColor.yellow)
            .clipShape(RoundedRectangle(cornerRadius: PadelMetrics.radiusControl, style: .continuous))
    }
}

/// The two-tone, tap-to-score scoreboard used on every live-scoring watch screen: each half is
/// a full-bleed color block for one team, with its name, current points, and an optional badge
/// (e.g. `DeuceBadge`) below the points. Tapping a half scores a point for that team.
public struct SplitScoreboard: View {
    private let teamAName: String
    private let teamBName: String
    private let pointsA: String
    private let pointsB: String
    private let badge: String?
    private let onTap: (Team) -> Void

    public init(
        teamAName: String, teamBName: String, pointsA: String, pointsB: String,
        badge: String? = nil, onTap: @escaping (Team) -> Void
    ) {
        self.teamAName = teamAName
        self.teamBName = teamBName
        self.pointsA = pointsA
        self.pointsB = pointsB
        self.badge = badge
        self.onTap = onTap
    }

    public var body: some View {
        VStack(spacing: 0) {
            half(name: teamAName, points: pointsA, team: .a, showsBadgeBelow: true)
            half(name: teamBName, points: pointsB, team: .b, showsBadgeBelow: false)
        }
        .clipShape(RoundedRectangle(cornerRadius: PadelMetrics.radiusScoreSplit, style: .continuous))
    }

    private func half(name: String, points: String, team: Team, showsBadgeBelow: Bool) -> some View {
        VStack(spacing: PadelMetrics.spacing6) {
            if !showsBadgeBelow { Text(points).font(PadelFont.scorePoints).foregroundStyle(PadelColor.textPrimary) }
            Text(name.uppercased())
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(TeamStyle.accent(for: team))
            if showsBadgeBelow { Text(points).font(PadelFont.scorePoints).foregroundStyle(PadelColor.textPrimary) }
            if showsBadgeBelow, let badge { DeuceBadge(badge) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, PadelMetrics.spacing18)
        .background(TeamStyle.background(for: team))
        .contentShape(Rectangle())
        .onTapGesture { onTap(team) }
    }
}

#Preview {
    SplitScoreboard(
        teamAName: "Luís & Rui", teamBName: "Tiago & André",
        pointsA: "40", pointsB: "40", badge: "STAR POINT", onTap: { _ in }
    )
    .padding()
    .background(PadelColor.background)
}
