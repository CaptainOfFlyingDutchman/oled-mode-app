import AppKit
import SwiftUI

extension Notification.Name {
    static let oledDeckMeasured = Notification.Name("oledDeckMeasured")
}

struct WindowAccessor: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.start()
        let view = FitView()
        DispatchQueue.main.async {
            context.coordinator.configure(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.configure(nsView.window)
        }
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator {
        private var token: NSObjectProtocol?
        private var lastSize: CGSize = .zero
        private weak var window: NSWindow?

        func start() {
            guard token == nil else { return }
            token = NotificationCenter.default.addObserver(
                forName: .oledDeckMeasured,
                object: nil,
                queue: .main
            ) { [weak self] note in
                guard let size = note.userInfo?["size"] as? CGSize else { return }
                self?.apply(size)
            }
        }

        func stop() {
            if let token {
                NotificationCenter.default.removeObserver(token)
                self.token = nil
            }
        }

        func configure(_ window: NSWindow?) {
            guard let window else { return }
            self.window = window
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.14, alpha: 1)
            window.isOpaque = true
            window.hasShadow = true
            window.isRestorable = false
            window.setFrameAutosaveName("")
            window.standardWindowButton(.zoomButton)?.isHidden = false
            applyHostingIntrinsicSize(from: window.contentView)
            window.invalidateShadow()
            DispatchQueue.main.async {
                window.makeFirstResponder(nil)
            }
        }

        private func apply(_ size: CGSize) {
            guard size.width > 1, size.height > 1 else { return }
            guard abs(size.width - lastSize.width) > 0.5 || abs(size.height - lastSize.height) > 0.5 else {
                return
            }
            lastSize = size
            guard let window else { return }
            let current = window.contentRect(forFrameRect: window.frame).size
            if abs(current.height - size.height) > 0.5 || abs(current.width - size.width) > 0.5 {
                window.setContentSize(NSSize(width: size.width, height: size.height))
            }
        }

        private func applyHostingIntrinsicSize(from view: NSView?) {
            guard let view else { return }
            if NSStringFromClass(type(of: view)).contains("NSHostingView") {
                view.setValue(NSHostingSizingOptions.intrinsicContentSize.rawValue, forKey: "sizingOptions")
            }
            view.subviews.forEach { applyHostingIntrinsicSize(from: $0) }
        }
    }
}

private final class FitView: NSView {
    override var isHidden: Bool {
        get { super.isHidden }
        set { super.isHidden = newValue }
    }
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
    }

    private func report(_ size: CGSize) {
        NotificationCenter.default.post(
            name: .oledDeckMeasured,
            object: nil,
            userInfo: ["size": size]
        )
    }
}
