import SwiftUI

/// Color tokens for the PadelScore dark UI, mirroring `design/mockups/index.html`.
///
/// The design is dark-only (no light-mode variant), so these are plain `Color` values
/// rather than asset-catalog colors — there is nothing for an asset catalog to switch between,
/// and package resource processing is avoidable risk under a bare `swift build`.
public enum PadelColor {
    public static let background = Color(hex: 0x0B0E14)
    public static let surface = Color(hex: 0x161B24)
    public static let surface2 = Color(hex: 0x1E2530)
    public static let border = Color(hex: 0x2A3241)

    /// Was black in the original mockup export, illegible on dark backgrounds. Use for
    /// titles, names, and numeric values.
    public static let textPrimary = Color(hex: 0xF5F7FA)
    /// Muted labels/captions — already had correct contrast in the original export.
    public static let textSecondary = Color(hex: 0x98A2B3)
    /// For text/icons drawn on top of a bright accent fill (mint, yellow) — keep dark here.
    public static let textOnAccent = Color(hex: 0x0B0E14)

    public static let mint = Color(hex: 0x2FE6A8)
    public static let blue = Color(hex: 0x4C8DFF)
    public static let blueBackground = Color(hex: 0x16233B)
    public static let orange = Color(hex: 0xFF9F55)
    public static let orangeBackground = Color(hex: 0x3B2416)
    public static let red = Color(hex: 0xFF5C5C)
    public static let redBackground = Color(hex: 0x3A1414)
    public static let yellow = Color(hex: 0xF5C93B)
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
