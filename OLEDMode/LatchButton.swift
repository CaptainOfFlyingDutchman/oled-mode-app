import AppKit
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
                    .tracking(isPower ? 2.4 : 0.8)
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
        LatchChrome(
            configuration: configuration,
            isLatched: isLatched,
            isPower: isPower,
            isEnabled: isEnabled
        )
    }
}

private struct LatchChrome: View {
    let configuration: ButtonStyleConfiguration
    var isLatched: Bool
    var isPower: Bool
    var isEnabled: Bool
    @State private var isHovered = false

    var body: some View {
        let sunk = isLatched || configuration.isPressed
        let hovering = isHovered && isEnabled
        let radius: CGFloat = isPower ? 18 : 8
        configuration.label
            .foregroundStyle(labelColor(sunk: sunk, hovering: hovering))
            .background(face(sunk: sunk, hovering: hovering))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(rimColor(sunk: sunk, hovering: hovering), lineWidth: rimWidth(hovering: hovering))
            }
            .shadow(color: glowColor(sunk: sunk, hovering: hovering), radius: glowRadius(sunk: sunk, hovering: hovering))
            .shadow(
                color: Color.black.opacity(sunk ? 0.2 : 0.55),
                radius: sunk ? 1 : 4,
                x: 0,
                y: sunk ? 1 : 3
            )
            .opacity(isEnabled ? 1 : 0.38)
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .onHover { hovering in
                isHovered = hovering
                updateCursor(hovering: hovering)
            }
            .onDisappear { updateCursor(hovering: false) }
            .animation(.easeOut(duration: 0.14), value: isHovered)
    }

    private func face(sunk: Bool, hovering: Bool) -> some View {
        let radius: CGFloat = isPower ? 18 : 8
        return RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: sunk
                        ? [
                            DeckTheme.amber.opacity(hovering && isLatched ? 1 : 0.95),
                            hovering && isLatched ? DeckTheme.amber.opacity(0.52) : DeckTheme.amberDim
                          ]
                        : [DeckTheme.raisedTop, DeckTheme.raisedBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                if hovering && !sunk {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(DeckTheme.amber.opacity(isPower ? 0.14 : 0.10))
                }
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(sunk ? 0.08 : (hovering ? 0.30 : 0.18)),
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
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(Color.black.opacity(0.45), lineWidth: 3)
                        .blur(radius: 1.5)
                        .padding(1)
                }
            }
    }

    private func labelColor(sunk: Bool, hovering: Bool) -> Color {
        if !isEnabled { return DeckTheme.textDim }
        if sunk { return DeckTheme.chassisDeep }
        return hovering ? DeckTheme.amberHot : DeckTheme.text
    }

    private func rimColor(sunk: Bool, hovering: Bool) -> Color {
        if hovering {
            return sunk ? DeckTheme.amberHot : DeckTheme.amber.opacity(0.75)
        }
        if isLatched && !isPower {
            return DeckTheme.amberHot.opacity(0.9)
        }
        return .clear
    }

    private func rimWidth(hovering: Bool) -> CGFloat {
        if hovering { return isPower ? 1.6 : 1.3 }
        if isLatched && !isPower { return 1.2 }
        return 0
    }

    private func updateCursor(hovering: Bool) {
        if hovering && isEnabled {
            NSCursor.pointingHand.set()
        } else {
            NSCursor.arrow.set()
        }
    }

    private func glowColor(sunk: Bool, hovering: Bool) -> Color {
        guard isEnabled else { return .clear }
        if sunk && isLatched {
            return DeckTheme.amber.opacity(hovering ? (isPower ? 0.85 : 0.62) : (isPower ? 0.65 : 0.45))
        }
        if hovering {
            return DeckTheme.amber.opacity(isPower ? 0.38 : 0.22)
        }
        return .clear
    }

    private func glowRadius(sunk: Bool, hovering: Bool) -> CGFloat {
        if sunk && isLatched {
            return (isPower ? 16 : 8) + (hovering ? 6 : 0)
        }
        if hovering {
            return isPower ? 14 : 8
        }
        return 0
    }
}

struct StatusLED: View {
    var isOn: Bool
    var isOffline: Bool = false
    var isError: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(DeckTheme.recessed)
                .frame(width: 14, height: 14)
            Circle()
                .fill(ledColor)
                .frame(width: 8, height: 8)
                .shadow(color: glowColor, radius: 6)
        }
        .overlay(
            Circle()
                .stroke(DeckTheme.bezel.opacity(0.7), lineWidth: 1)
        )
    }

    private var ledColor: Color {
        if isError { return DeckTheme.danger }
        if isOffline { return DeckTheme.textDim.opacity(0.4) }
        return isOn ? DeckTheme.amber : DeckTheme.textDim.opacity(0.35)
    }

    private var glowColor: Color {
        if isError { return DeckTheme.danger.opacity(0.9) }
        if isOn && !isOffline { return DeckTheme.amber.opacity(0.9) }
        return .clear
    }
}
