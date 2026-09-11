import SwiftUI
import PadelCore

/// Screen 17 — court calibration complete, ready to be saved as a `CourtCalibrationRecord` for
/// `location` (persistence is the composition root's job, Fase 3).
public struct CourtCalibrationCompleteScreen: View {
    private let location: String
    private let calibration: CourtCalibration
    private let onDone: () -> Void

    public init(location: String, calibration: CourtCalibration, onDone: @escaping () -> Void) {
        self.location = location
        self.calibration = calibration
        self.onDone = onDone
    }

    public var body: some View {
        VStack(spacing: PadelMetrics.spacing12) {
            Text("Campo calibrado").font(PadelFont.sectionLabel).foregroundStyle(PadelColor.textSecondary)
            Image(systemName: "checkmark").foregroundStyle(PadelColor.mint)
            Text(location).font(PadelFont.cardTitle).foregroundStyle(PadelColor.textPrimary)
            Text("\(calibration.points.count) pontos marcados · pronto para o heatmap")
                .font(PadelFont.statLabel).foregroundStyle(PadelColor.textSecondary)
            Button("Concluído", action: onDone).buttonStyle(.padelSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(PadelMetrics.spacing12)
        .background(PadelColor.background)
    }
}

#Preview {
    var calibration = CourtCalibration()
    for landmark in CourtLandmark.allCases {
        calibration.points[landmark] = GeoPoint(latitude: 38.7, longitude: -9.1)
    }
    return CourtCalibrationCompleteScreen(location: "Padel Norte", calibration: calibration, onDone: {})
}
