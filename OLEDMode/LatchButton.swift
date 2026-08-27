import SwiftUI

struct LatchButton: View {
    let title: String
    var subtitle: String? = nil
    var isLatched: Bool
    var isEnabled: Bool = true
    var isPower: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: isPower ? 6 : 2) {
                Text(title)
                    .font(DeckTheme.hudFont(isPower ? 18 : 11, weight: .heavy))
                    .tracking(isPower ? 4 : 0.8)
                if let subtitle {
                    Text(subtitle)
                        .font(DeckTheme.hudFont(isPower ? 12 : 8, weight: .bold))
                        .tracking(1.2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isPower ? 88 : 44)
        }
        .buttonStyle(
            LatchButtonStyle(
                isLatched: isLatched,
                isPower: isPower,
                isEnabled: isEnabled
            )
        )
        .focusable(false)
        .focusEffectDisabled()
        .disabled(!isEnabled)
    }
}

struct LatchButtonStyle: ButtonStyle {
    var isLatched: Bool
    var isPower: Bool
    var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        let sunk = isLatched || configuration.isPressed
        let radius: CGFloat = isPower ? 18 : 8
        configuration.label
            .foregroundStyle(labelColor(sunk: sunk))
            .background(face(sunk: sunk))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                if isLatched && !isPower {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(DeckTheme.amberHot.opacity(0.9), lineWidth: 1.2)
                }
            }
            .shadow(color: glowColor(sunk: sunk), radius: sunk && isLatched ? (isPower ? 16 : 8) : 0)
            .shadow(
                color: Color.black.opacity(sunk ? 0.2 : 0.55),
                radius: sunk ? 1 : 4,
                x: 0,
                y: sunk ? 1 : 3
            )
            .opacity(isEnabled ? 1 : 0.38)
    }

    private func face(sunk: Bool) -> some View {
        RoundedRectangle(cornerRadius: isPower ? 18 : 8, style: .continuous)
            .fill(
                LinearGradient(
                    colors: sunk
                        ? [DeckTheme.amber.opacity(0.95), DeckTheme.amberDim]
                        : [DeckTheme.raisedTop, DeckTheme.raisedBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: isPower ? 18 : 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(sunk ? 0.08 : 0.18),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .padding(1)
            }
            .overlay {
                if sunk {
                    RoundedRectangle(cornerRadius: isPower ? 18 : 8, style: .continuous)
                        .stroke(Color.black.opacity(0.45), lineWidth: 3)
                        .blur(radius: 1.5)
                        .padding(1)
                }
            }
    }

    private func labelColor(sunk: Bool) -> Color {
        if !isEnabled { return DeckTheme.textDim }
        return sunk ? DeckTheme.chassisDeep : DeckTheme.text
    }

    private func glowColor(sunk: Bool) -> Color {
        guard sunk, isLatched, isEnabled else { return .clear }
        return DeckTheme.amber.opacity(isPower ? 0.65 : 0.45)
    }
}

struct StatusLED: View {
    var isOn: Bool
    var isOffline: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(DeckTheme.recessed)
                .frame(width: 14, height: 14)
            Circle()
                .fill(ledColor)
                .frame(width: 8, height: 8)
                .shadow(color: ledColor.opacity(isOn && !isOffline ? 0.9 : 0), radius: 6)
        }
        .overlay(
            Circle()
                .stroke(DeckTheme.bezel.opacity(0.7), lineWidth: 1)
        )
    }

    private var ledColor: Color {
        if isOffline { return DeckTheme.textDim.opacity(0.4) }
        return isOn ? DeckTheme.amber : DeckTheme.textDim.opacity(0.35)
    }
}
