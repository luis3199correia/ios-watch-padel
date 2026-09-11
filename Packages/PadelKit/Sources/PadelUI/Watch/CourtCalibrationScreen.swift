import SwiftUI
import PadelCore

/// Screen 16 — court calibration, walking to and marking one of the 6 landmarks. `onMark` is a
/// plain closure (decisions.md #9, rule 2): the composition root captures the real `GeoPoint`
/// from CoreLocation and calls `viewModel.mark(at:)` — this view never touches CoreLocation.
public struct CourtCalibrationScreen: View {
    private let viewModel: CourtCalibrationViewModel
    private let onMark: () -> Void

    public init(viewModel: CourtCalibrationViewModel, onMark: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onMark = onMark
    }

    public var body: some View {
        VStack(spacing: PadelMetrics.spacing12) {
            Text("Calibrar Campo · Passo \(viewModel.stepNumber)/\(viewModel.totalSteps)")
                .font(PadelFont.sectionLabel).foregroundStyle(PadelColor.textSecondary)

            if let landmark = viewModel.currentLandmark {
                PadelCard {
                    VStack(spacing: PadelMetrics.spacing8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 30)).foregroundStyle(PadelColor.mint)
                        Text(CalibrationLabels.landmarkName(landmark))
                            .font(PadelFont.cardTitle).foregroundStyle(PadelColor.textPrimary)
                        Text("Vai até lá e toca em Marcar")
                            .font(PadelFont.statLabel).foregroundStyle(PadelColor.textSecondary)
                    }
                }
            }

            StepDots(total: viewModel.totalSteps, completed: viewModel.currentIndex)

            Button {
                onMark()
            } label: {
                Label("Marcar", systemImage: "mappin.and.ellipse")
            }
            .buttonStyle(.padelPrimary)
        }
        .multilineTextAlignment(.center)
        .padding(PadelMetrics.spacing12)
        .background(PadelColor.background)
    }
}

#Preview {
    CourtCalibrationScreen(viewModel: CourtCalibrationViewModel(), onMark: {})
}
