import SwiftUI

/// Generic dark surface container, e.g. `.card { rows... }`.
public struct PadelCard<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        content
            .padding(PadelMetrics.spacing14)
            .background(PadelColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: PadelMetrics.radiusCard, style: .continuous))
    }
}

/// A muted numeric/text pill, e.g. a completed set score ("6-4").
public struct PadelPill: View {
    private let text: String
    public init(_ text: String) { self.text = text }

    public var body: some View {
        Text(text)
            .font(PadelFont.pillText)
            .foregroundStyle(PadelColor.textPrimary)
            .padding(.horizontal, PadelMetrics.spacing12)
            .padding(.vertical, PadelMetrics.spacing6)
            .background(PadelColor.surface2)
            .clipShape(RoundedRectangle(cornerRadius: PadelMetrics.radiusPill, style: .continuous))
    }
}

/// A short accent-filled label, e.g. "MIX" or "RONDA 3". Dark text on a bright fill always has
/// good contrast, so this never needed the black-on-dark fix the rest of the UI did.
public struct PadelBadge: View {
    private let text: String
    private let tint: Color
    public init(_ text: String, tint: Color = PadelColor.mint) {
        self.text = text
        self.tint = tint
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy))
            .foregroundStyle(PadelColor.textOnAccent)
            .padding(.horizontal, PadelMetrics.spacing8)
            .padding(.vertical, 3)
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: PadelMetrics.radiusBadge, style: .continuous))
    }
}

#Preview {
    VStack(spacing: PadelMetrics.spacing12) {
        PadelCard { Text("Card content").foregroundStyle(PadelColor.textPrimary) }
        HStack { PadelPill("6-4"); PadelPill("7-6(5)") }
        HStack { PadelBadge("MIX"); PadelBadge("RONDA 3") }
    }
    .padding()
    .background(PadelColor.background)
}
