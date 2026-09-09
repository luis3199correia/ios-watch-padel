import SwiftUI
import PadelCore

/// Per-team accent/background colors. `.a` is always "my team" (see decisions.md 8b: in Mix
/// rounds, the local player's side is always `.a`).
public enum TeamStyle {
    public static func accent(for team: Team) -> Color {
        team == .a ? PadelColor.blue : PadelColor.orange
    }

    public static func background(for team: Team) -> Color {
        team == .a ? PadelColor.blueBackground : PadelColor.orangeBackground
    }
}
