import SwiftUI
import PadelCore

/// Screen 19 — stroke calibration complete, listing every calibrated shot type. `profiles` is
/// ready to be saved via `StrokeProfileRepository.save` (composition root's job, Fase 3).
public struct StrokeCalibrationCompleteScreen: View {
    private let profiles: [StrokeProfile]
    private let onDone: () -> Void

    public init(profiles: [StrokeProfile], onDone: @escaping () -> Void) {
        self.profiles = profiles
        self.onDone = onDone
    }

    public var body: some View {
        VStack(spacing: PadelMetrics.spacing12) {
            Text("Pancadas calibradas").font(PadelFont.sectionLabel).foregroundStyle(PadelColor.textSecondary)
            Image(systemName: "checkmark").foregroundStyle(PadelColor.mint)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: PadelMetrics.spacing6)], spacing: PadelMetrics.spacing6) {
                ForEach(profiles, id: \.shotType) { profile in
                    PadelPill(CalibrationLabels.shotTypeName(profile.shotType))
                }
            }

            Button("Concluído", action: onDone).buttonStyle(.padelSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(PadelMetrics.spacing12)
        .background(PadelColor.background)
    }
}

#Preview {
    let profiles = ShotType.allCases.map {
        StrokeProfile(shotType: $0, referenceSamples: [
            MotionSample(peakAcceleration: 2, peakRotationRate: 4, duration: 0.2, directionDegrees: 0),
        ])
    }
    return StrokeCalibrationCompleteScreen(profiles: profiles, onDone: {})
}
