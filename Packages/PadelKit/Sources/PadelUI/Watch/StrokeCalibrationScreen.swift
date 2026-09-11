import SwiftUI
import PadelCore

/// Screen 18 — stroke calibration, recording one repetition of the current shot type. `onRecord`
/// is a plain closure (decisions.md #9, rule 2): the composition root extracts the real
/// `MotionSample` from CoreMotion and calls `viewModel.record(_:)` — this view never touches
/// CoreMotion.
public struct StrokeCalibrationScreen: View {
    private let viewModel: StrokeCalibrationViewModel
    private let onRecord: () -> Void

    public init(viewModel: StrokeCalibrationViewModel, onRecord: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onRecord = onRecord
    }

    public var body: some View {
        VStack(spacing: PadelMetrics.spacing12) {
            Text("Calibrar Pancadas · \(viewModel.stepNumber)/\(viewModel.totalSteps)")
                .font(PadelFont.sectionLabel).foregroundStyle(PadelColor.textSecondary)

            if let shotType = viewModel.currentShotType {
                PadelCard {
                    VStack(spacing: PadelMetrics.spacing8) {
                        Image(systemName: "tennisball.fill")
                            .font(.system(size: 30)).foregroundStyle(PadelColor.mint)
                        Text(CalibrationLabels.shotTypeName(shotType))
                            .font(PadelFont.cardTitle).foregroundStyle(PadelColor.textPrimary)
                        Text("Repetição \(viewModel.currentRepNumber) de \(StrokeCalibrationViewModel.repsPerType) — faz o gesto quando estiveres pronto")
                            .font(PadelFont.statLabel).foregroundStyle(PadelColor.textSecondary)
                    }
                }
            }

            Button {
                onRecord()
            } label: {
                Label("Gravar", systemImage: "record.circle")
            }
            .buttonStyle(.padelPrimary)
        }
        .multilineTextAlignment(.center)
        .padding(PadelMetrics.spacing12)
        .background(PadelColor.background)
    }
}

#Preview {
    StrokeCalibrationScreen(viewModel: StrokeCalibrationViewModel(), onRecord: {})
}
