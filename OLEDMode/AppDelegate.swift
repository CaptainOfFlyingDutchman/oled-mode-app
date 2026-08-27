import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = OLEDController()
    private var panel: NSWindow?
    private var sizeObserver: NSObjectProtocol?

    func applicationWillFinishLaunching(_ notification: Notification) {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.contains("NSWindow Frame") {
            defaults.removeObject(forKey: key)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        showPanel()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPanel()
        sender.activate(ignoringOtherApps: true)
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func showPanel() {
        if let panel {
            panel.makeKeyAndOrderFront(nil)
            return
        }
        panel = makeWindow()
    }

    private func makeWindow() -> NSWindow {
        let hosting = NSHostingController(
            rootView: ControlDeckView().environmentObject(controller)
        )
        hosting.sizingOptions = .intrinsicContentSize

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 448, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "OLED Mode"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.14, alpha: 1)
        window.isOpaque = true
        window.hasShadow = true
        window.isRestorable = false
        window.setFrameAutosaveName("")
        window.isReleasedWhenClosed = false
        window.contentViewController = hosting

        sizeObserver = NotificationCenter.default.addObserver(
            forName: .oledDeckMeasured,
            object: nil,
            queue: .main
        ) { [weak window] note in
            guard let window,
                  let size = note.userInfo?["size"] as? CGSize,
                  size.width > 1,
                  size.height > 1 else { return }
            let current = window.contentRect(forFrameRect: window.frame).size
            if abs(current.height - size.height) > 0.5 || abs(current.width - size.width) > 0.5 {
                window.setContentSize(NSSize(width: size.width, height: size.height))
            }
        }

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return window
    }
}
