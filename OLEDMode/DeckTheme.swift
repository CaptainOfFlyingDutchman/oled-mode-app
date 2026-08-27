import SwiftUI

enum DeckTheme {
    static let chassis = Color(red: 0.10, green: 0.11, blue: 0.14)
    static let chassisDeep = Color(red: 0.07, green: 0.08, blue: 0.10)
    static let bezel = Color(red: 0.28, green: 0.30, blue: 0.36)
    static let raisedTop = Color(red: 0.24, green: 0.26, blue: 0.32)
    static let raisedBottom = Color(red: 0.13, green: 0.14, blue: 0.18)
    static let recessed = Color(red: 0.05, green: 0.055, blue: 0.07)
    static let amber = Color(red: 1.00, green: 0.69, blue: 0.13)
    static let amberHot = Color(red: 1.00, green: 0.86, blue: 0.42)
    static let amberDim = Color(red: 0.42, green: 0.26, blue: 0.04)
    static let text = Color(red: 0.86, green: 0.88, blue: 0.91)
    static let textDim = Color(red: 0.48, green: 0.51, blue: 0.58)
    static let danger = Color(red: 0.95, green: 0.32, blue: 0.28)

    static func hudFont(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
