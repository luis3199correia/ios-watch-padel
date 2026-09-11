import SwiftUI

/// A row of step-progress dots — filled for completed steps, muted for the rest. Used by the
/// court-calibration flow (screen 16 in `design/mockups/index.html`).
public struct StepDots: View {
    private let total: Int
    private let completed: Int

    public init(total: Int, completed: Int) {
        self.total = total
        self.completed = completed
    }

    public var body: some View {
        HStack(spacing: PadelMetrics.spacing6) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < completed ? PadelColor.mint : PadelColor.surface2)
                    .frame(width: PadelMetrics.dotSize, height: PadelMetrics.dotSize)
            }
        }
    }
}

#Preview {
    StepDots(total: 6, completed: 2)
        .padding()
        .background(PadelColor.background)
}
