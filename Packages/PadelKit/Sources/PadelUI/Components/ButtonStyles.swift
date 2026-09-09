import SwiftUI

public struct PadelPrimaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .heavy))
            .foregroundStyle(PadelColor.textOnAccent)
            .frame(maxWidth: .infinity)
            .padding(PadelMetrics.spacing14)
            .background(PadelColor.mint)
            .clipShape(RoundedRectangle(cornerRadius: PadelMetrics.radiusControl, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

public struct PadelSecondaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(PadelColor.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(PadelMetrics.spacing12)
            .background(PadelColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: PadelMetrics.radiusControl, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

public struct PadelDangerButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .heavy))
            .foregroundStyle(PadelColor.red)
            .frame(maxWidth: .infinity)
            .padding(PadelMetrics.spacing12)
            .background(PadelColor.redBackground)
            .overlay {
                RoundedRectangle(cornerRadius: PadelMetrics.radiusControl, style: .continuous)
                    .strokeBorder(PadelColor.red, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: PadelMetrics.radiusControl, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

public struct PadelConfirmButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .heavy))
            .foregroundStyle(PadelColor.mint)
            .frame(maxWidth: .infinity)
            .padding(PadelMetrics.spacing12)
            .background(PadelColor.mint.opacity(0.10))
            .overlay {
                RoundedRectangle(cornerRadius: PadelMetrics.radiusControl, style: .continuous)
                    .strokeBorder(PadelColor.mint, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: PadelMetrics.radiusControl, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == PadelPrimaryButtonStyle {
    public static var padelPrimary: PadelPrimaryButtonStyle { .init() }
}
extension ButtonStyle where Self == PadelSecondaryButtonStyle {
    public static var padelSecondary: PadelSecondaryButtonStyle { .init() }
}
extension ButtonStyle where Self == PadelDangerButtonStyle {
    public static var padelDanger: PadelDangerButtonStyle { .init() }
}
extension ButtonStyle where Self == PadelConfirmButtonStyle {
    public static var padelConfirm: PadelConfirmButtonStyle { .init() }
}

#Preview {
    VStack(spacing: PadelMetrics.spacing10) {
        Button("Iniciar Sessão no Watch") {}.buttonStyle(.padelPrimary)
        Button("Concluído") {}.buttonStyle(.padelSecondary)
        Button("Terminar jogo") {}.buttonStyle(.padelDanger)
        Button("Terminar Partida") {}.buttonStyle(.padelConfirm)
    }
    .padding()
    .background(PadelColor.background)
}
