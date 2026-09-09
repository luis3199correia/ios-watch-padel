import SwiftUI
#if os(watchOS)
import WatchKit
#endif

/// The only file in `PadelUI` allowed to branch on `#if os(...)` (see decisions.md #9) — every
/// other file must be cross-platform SwiftUI so a plain macOS `swift build` type-checks it.
extension View {
    /// Page-style, dot-indicator tab view — the watch convention for swiping between screens.
    @ViewBuilder
    func padelPageTabStyle() -> some View {
        #if os(watchOS)
        self.tabViewStyle(.page)
        #else
        self.tabViewStyle(.automatic)
        #endif
    }
}

public enum PadelHaptics {
    /// Light tick feedback for a scored point. No-op on platforms without a haptic engine.
    public static func tick() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
    }
}
