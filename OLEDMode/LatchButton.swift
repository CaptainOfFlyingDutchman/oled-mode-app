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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let sunk = isLatched || configuration.isPressed
        let hovering = isHovered && isEnabled
        let radius: CGFloat = isPower ? 18 : 8
        configuration.label
            .foregroundStyle(labelColor(hovering: hovering))
            .background(face(sunk: sunk, hovering: hovering))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(rimColor(hovering: hovering), lineWidth: rimWidth(hovering: hovering))
            }
            .shadow(
                color: DeckTheme.amber.opacity(glowOpacity(hovering: hovering)),
                radius: glowRadius(hovering: hovering)
            )
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
            .animation(reduceMotion ? nil : DeckTheme.Motion.hover, value: isHovered)
            .animation(reduceMotion ? nil : DeckTheme.Motion.press, value: configuration.isPressed)
            .animation(reduceMotion ? nil : DeckTheme.Motion.latch(isLatched), value: isLatched)
    }

    private func face(sunk: Bool, hovering: Bool) -> some View {
        let radius: CGFloat = isPower ? 18 : 8
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return shape
            .fill(
                LinearGradient(
                    colors: [DeckTheme.raisedTop, DeckTheme.raisedBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                shape
                    .fill(Color.black.opacity(0.22))
                    .opacity(sunk && !isLatched ? 1 : 0)
            }
            .overlay {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                DeckTheme.amber.opacity(hovering ? 1 : 0.95),
                                hovering ? DeckTheme.amber.opacity(0.52) : DeckTheme.amberDim
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(isLatched ? 1 : 0)
            }
            .overlay {
                shape
                    .fill(DeckTheme.amber.opacity(isPower ? 0.16 : 0.12))
                    .blendMode(.softLight)
                    .opacity(hovering && !isLatched ? 1 : 0)
            }
            .overlay(alignment: .top) {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isLatched ? 0.08 : (hovering ? 0.22 : 0.16)),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .padding(1)
            }
            .overlay {
                shape
                    .stroke(Color.black.opacity(0.45), lineWidth: 3)
                    .blur(radius: 1.5)
                    .padding(1)
                    .opacity(sunk ? 1 : 0)
            }
            .overlay {
                LatchFaceTexture(isPower: isPower, sunk: sunk)
            }
            .clipShape(shape)
    }

    private func labelColor(hovering: Bool) -> Color {
        if !isEnabled { return DeckTheme.textDim }
        if isLatched { return DeckTheme.chassisDeep }
        return hovering ? DeckTheme.amberHot : DeckTheme.text
    }

    private func rimColor(hovering: Bool) -> Color {
        if hovering {
            return isLatched ? DeckTheme.amberHot : DeckTheme.amber.opacity(0.75)
        }
        if isLatched && !isPower {
            return DeckTheme.amberHot.opacity(0.9)
        }
        return DeckTheme.amber.opacity(0)
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

    private func glowOpacity(hovering: Bool) -> CGFloat {
        guard isEnabled else { return 0 }
        if isLatched {
            return hovering ? (isPower ? 0.85 : 0.62) : (isPower ? 0.65 : 0.45)
        }
        if hovering {
            return isPower ? 0.38 : 0.22
        }
        return 0
    }

    private func glowRadius(hovering: Bool) -> CGFloat {
        if isLatched {
            return (isPower ? 16 : 8) + (hovering ? 6 : 0)
        }
        if hovering {
            return isPower ? 14 : 8
        }
        return isPower ? 10 : 6
    }
}

private struct LatchFaceTexture: View {
    var isPower: Bool
    var sunk: Bool

    var body: some View {
        ZStack {
            mill
            Image(nsImage: LatchGrain.image)
                .interpolation(.medium)
                .resizable(resizingMode: .tile)
                .opacity(sunk ? 0.48 : 0.58)
                .blendMode(.overlay)
        }
        .allowsHitTesting(false)
    }

    private var mill: some View {
        Canvas { context, size in
            let step: CGFloat = isPower ? 2.0 : 1.75
            var y: CGFloat = 0
            var index = 0
            let dark = Color.black.opacity(sunk ? 0.10 : 0.16)
            let lite = Color.white.opacity(sunk ? 0.06 : 0.07)
            while y < size.height {
                var path = Path()
                path.addRect(CGRect(x: 0, y: y, width: size.width, height: 1))
                context.fill(path, with: .color(index.isMultiple(of: 2) ? dark : lite))
                y += step
                index += 1
            }
        }
        .blendMode(.overlay)
        .opacity(sunk ? 0.72 : 0.88)
    }
}

private enum LatchGrain {
    static let image: NSImage = render()

    private static func render() -> NSImage {
        let dim = 128
        var pixels = [UInt8](repeating: 0, count: dim * dim * 4)
        for i in 0..<(dim * dim) {
            let speck = mix(i, 0x9E37_79B9)
            guard speck % 9 == 0 else { continue }
            let alpha = UInt8(32 + mix(i, 0x85EB_CA6B) % 48)
            let offset = i * 4
            if mix(i, 0xC2B2_AE35) & 1 == 0 {
                pixels[offset] = alpha
                pixels[offset + 1] = alpha
                pixels[offset + 2] = alpha
            }
            pixels[offset + 3] = alpha
        }
        let data = Data(pixels)
        let space = CGColorSpaceCreateDeviceRGB()
        guard
            let provider = CGDataProvider(data: data as CFData),
            let cgImage = CGImage(
                width: dim,
                height: dim,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: dim * 4,
                space: space,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else {
            return NSImage()
        }
        return NSImage(cgImage: cgImage, size: NSSize(width: 64, height: 64))
    }

    private static func mix(_ value: Int, _ seed: UInt32) -> Int {
        var hash = UInt32(truncatingIfNeeded: value) &* 0x85EB_CA6B
        hash ^= seed
        hash ^= hash >> 13
        hash = hash &* 0xC2B2_AE35
        hash ^= hash >> 16
        return Int(hash)
    }
}

struct StatusLED: View {
    var isOn: Bool
    var isOffline: Bool = false
    var isError: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let lit = isOn && !isOffline && !isError
        ZStack {
            Circle()
                .fill(DeckTheme.recessed)
                .frame(width: 14, height: 14)
            Circle()
                .fill(DeckTheme.textDim.opacity(isOffline ? 0.4 : 0.35))
                .frame(width: 8, height: 8)
            Circle()
                .fill(DeckTheme.amber)
                .frame(width: 8, height: 8)
                .shadow(color: DeckTheme.amber.opacity(lit ? 0.9 : 0), radius: 6)
                .opacity(lit ? 1 : 0)
            Circle()
                .fill(DeckTheme.danger)
                .frame(width: 8, height: 8)
                .shadow(color: DeckTheme.danger.opacity(isError ? 0.9 : 0), radius: 6)
                .opacity(isError ? 1 : 0)
        }
        .overlay(
            Circle()
                .stroke(DeckTheme.bezel.opacity(0.7), lineWidth: 1)
        )
        .animation(reduceMotion ? nil : DeckTheme.Motion.led(lit), value: lit)
        .animation(reduceMotion ? nil : DeckTheme.Motion.led(isError), value: isError)
    }
}
