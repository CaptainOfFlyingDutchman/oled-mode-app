import SwiftUI

@main
struct OLEDModeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = OLEDController()

    var body: some Scene {
        WindowGroup("OLED Mode", id: "main") {
            ControlDeckView()
                .environmentObject(controller)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .windowIdealSize(.fitToContent)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
