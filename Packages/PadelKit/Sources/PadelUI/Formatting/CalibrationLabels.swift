import PadelCore

/// Portuguese display names for the court/stroke calibration enums (decisions.md #9, rule 6 —
/// kept out of PadelCore, same pattern as `MatchLabels`).
public enum CalibrationLabels {
    public static func landmarkName(_ landmark: CourtLandmark) -> String {
        switch landmark {
        case .cornerNearLeft: return "Canto perto-esquerda"
        case .cornerNearRight: return "Canto perto-direita"
        case .cornerFarLeft: return "Canto longe-esquerda"
        case .cornerFarRight: return "Canto longe-direita"
        case .netLeft: return "Poste da rede-esquerda"
        case .netRight: return "Poste da rede-direita"
        }
    }

    public static func shotTypeName(_ shotType: ShotType) -> String {
        switch shotType {
        case .forehand: return "Forehand"
        case .backhand: return "Backhand"
        case .volley: return "Volley"
        case .bandeja: return "Bandeja"
        case .vibora: return "Víbora"
        case .smash: return "Smash"
        case .serve: return "Serviço"
        case .bajada: return "Bajada"
        case .rulo: return "Rulo"
        case .chiquita: return "Chiquita"
        case .lob: return "Balão"
        }
    }
}
