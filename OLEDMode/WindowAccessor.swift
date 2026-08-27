import SwiftUI

extension Notification.Name {
    static let oledDeckMeasured = Notification.Name("oledDeckMeasured")
}

struct DeckSizeReporter: View {
    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { report(proxy.size) }
                .onChange(of: proxy.size) { _, newSize in
                    report(newSize)
                }
        }
        .allowsHitTesting(false)
    }

    private func report(_ size: CGSize) {
        guard size.width > 1, size.height > 1 else { return }
        NotificationCenter.default.post(
            name: .oledDeckMeasured,
            object: nil,
            userInfo: ["size": size]
        )
    }
}
