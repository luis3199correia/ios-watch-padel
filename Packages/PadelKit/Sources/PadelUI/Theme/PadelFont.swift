import SwiftUI

/// Typography scale mirroring `design/mockups/index.html`.
public enum PadelFont {
    public static let pageTitle = Font.system(size: 30, weight: .heavy, design: .rounded)
    public static let pageTitleCompact = Font.system(size: 20, weight: .heavy, design: .rounded) // watch
    public static let pageSubtitle = Font.system(size: 13, weight: .regular)
    public static let sectionLabel = Font.system(size: 11, weight: .bold).uppercaseSmallCaps()
    public static let cardTitle = Font.system(size: 14, weight: .heavy)
    public static let statValue = Font.system(size: 20, weight: .heavy, design: .rounded)
    public static let statUnit = Font.system(size: 12, weight: .semibold)
    public static let statLabel = Font.system(size: 11, weight: .regular)
    public static let scorePoints = Font.system(size: 56, weight: .heavy, design: .rounded)
    public static let pillText = Font.system(size: 13, weight: .bold)
}
