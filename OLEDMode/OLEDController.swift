import AppKit
import Foundation
import SwiftUI

enum MenuBarMode: String, CaseIterable, Codable, Equatable {
    case never
    case fullScreenOnly
    case desktopOnly
    case always

    var buttonTitle: String {
        switch self {
        case .never: return "NEVER"
        case .fullScreenOnly: return "FULL SCR"
        case .desktopOnly: return "DESKTOP"
        case .always: return "ALWAYS"
        }
    }

    var hideOnDesktop: Bool {
        self == .always || self == .desktopOnly
    }

    var visibleInFullScreen: Bool {
        self == .never || self == .desktopOnly
    }

    static func from(hideOnDesktop: Bool, visibleInFullScreen: Bool) -> MenuBarMode {
        switch (hideOnDesktop, visibleInFullScreen) {
        case (true, false): return .always
        case (true, true): return .desktopOnly
        case (false, false): return .fullScreenOnly
        case (false, true): return .never
        }
    }
}

struct OLEDSnapshot: Codable, Equatable {
    var menuBar: MenuBarMode
    var dockHidden: Bool
    var stageHidden: Bool
}

@MainActor
final class OLEDController: ObservableObject {
    @Published var menuBarMode: MenuBarMode = .never
    @Published var dockHidden = false
    @Published var stageHidden = false
    @Published var stageManagerEnabled = false
    @Published var automationDenied = false
    @Published var statusLine = "SYS READY"

    private var snapshot: OLEDSnapshot?
    private let snapshotKey = "oled.snapshot"
    private let windowManagerID = "com.apple.WindowManager" as CFString

    var isPresetActive: Bool {
        menuBarMode == .always
            && dockHidden
            && (!stageManagerEnabled || stageHidden)
    }

    var footerText: String {
        if automationDenied {
            return "ALLOW AUTOMATION · SYSTEM EVENTS"
        }
        if isPresetActive {
            if stageManagerEnabled {
                return "PRESET ARMED · DOCK · MENU · STRIP"
            }
            return "PRESET ARMED · DOCK · MENU"
        }
        return "PRESET IDLE"
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: snapshotKey),
           let saved = try? JSONDecoder().decode(OLEDSnapshot.self, from: data) {
            snapshot = saved
        }
        refresh()
    }

    func refresh() {
        readStageManager()
        readMenuBarDefaults()
        readDockAndMenuBarLive()
        statusLine = footerText
    }

    func togglePower() {
        if isPresetActive {
            restoreSnapshot()
        } else {
            armPreset()
        }
    }

    func setMenuBarMode(_ mode: MenuBarMode) {
        applyMenuBar(mode)
        refresh()
    }

    func toggleDockHidden() {
        applyDock(hidden: !dockHidden)
        refresh()
    }

    func toggleStageHidden() {
        guard stageManagerEnabled else { return }
        applyStage(hidden: !stageHidden)
        refresh()
    }

    private func armPreset() {
        let snap = OLEDSnapshot(
            menuBar: menuBarMode,
            dockHidden: dockHidden,
            stageHidden: stageHidden
        )
        snapshot = snap
        persistSnapshot()
        applyMenuBar(.always)
        applyDock(hidden: true)
        if stageManagerEnabled {
            applyStage(hidden: true)
        }
        refresh()
    }

    private func restoreSnapshot() {
        let snap = snapshot ?? OLEDSnapshot(menuBar: .never, dockHidden: false, stageHidden: false)
        applyMenuBar(snap.menuBar)
        applyDock(hidden: snap.dockHidden)
        if stageManagerEnabled {
            applyStage(hidden: snap.stageHidden)
        }
        refresh()
    }

    private func persistSnapshot() {
        guard let snapshot,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: snapshotKey)
    }

    private func readDockAndMenuBarLive() {
        let script = """
        tell application "System Events"
          tell dock preferences
            set menuHidden to autohide menu bar
            set dockAuto to autohide
            return (menuHidden as text) & "," & (dockAuto as text)
          end tell
        end tell
        """
        do {
            let raw = try runAppleScript(script).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            automationDenied = false
            let parts = raw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                let hideDesktop = parts[0] == "true"
                dockHidden = parts[1] == "true"
                menuBarMode = MenuBarMode.from(
                    hideOnDesktop: hideDesktop,
                    visibleInFullScreen: menuBarMode.visibleInFullScreen
                )
            }
        } catch {
            automationDenied = true
        }
    }

    private func readMenuBarDefaults() {
        let hideDesktop = cfBool("_HIHideMenuBar", app: kCFPreferencesAnyApplication) ?? false
        let visibleFS = cfBool("AppleMenuBarVisibleInFullscreen", app: kCFPreferencesAnyApplication) ?? true
        menuBarMode = MenuBarMode.from(hideOnDesktop: hideDesktop, visibleInFullScreen: visibleFS)
    }

    private func readStageManager() {
        stageManagerEnabled = cfBool("GloballyEnabled", app: windowManagerID) ?? false
        stageHidden = cfBool("AutoHide", app: windowManagerID) ?? false
    }

    private func applyDock(hidden: Bool) {
        let flag = hidden ? "true" : "false"
        let script = """
        tell application "System Events"
          tell dock preferences
            set autohide to \(flag)
          end tell
        end tell
        """
        do {
            _ = try runAppleScript(script)
            automationDenied = false
        } catch {
            automationDenied = true
        }
    }

    private func applyMenuBar(_ mode: MenuBarMode) {
        cfSetBool("_HIHideMenuBar", value: mode.hideOnDesktop, app: kCFPreferencesAnyApplication)
        cfSetBool("AppleMenuBarVisibleInFullscreen", value: mode.visibleInFullScreen, app: kCFPreferencesAnyApplication)

        let flag = mode.hideOnDesktop ? "true" : "false"
        let script = """
        tell application "System Events"
          tell dock preferences
            set autohide menu bar to \(flag)
          end tell
        end tell
        """
        do {
            _ = try runAppleScript(script)
            automationDenied = false
        } catch {
            automationDenied = true
        }
    }

    private func applyStage(hidden: Bool) {
        cfSetBool("AutoHide", value: hidden, app: windowManagerID)
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        proc.arguments = [
            "write",
            "com.apple.WindowManager",
            "AutoHide",
            "-bool",
            hidden ? "true" : "false"
        ]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
        proc.waitUntilExit()
    }

    private func cfBool(_ key: String, app: CFString) -> Bool? {
        CFPreferencesAppSynchronize(app)
        guard let value = CFPreferencesCopyAppValue(key as CFString, app) else { return nil }
        if let number = value as? NSNumber { return number.boolValue }
        if let bool = value as? Bool { return bool }
        return nil
    }

    private func cfSetBool(_ key: String, value: Bool, app: CFString) {
        CFPreferencesSetAppValue(
            key as CFString,
            (value ? kCFBooleanTrue : kCFBooleanFalse) as CFBoolean,
            app
        )
        CFPreferencesAppSynchronize(app)
    }

    private func runAppleScript(_ source: String) throws -> String {
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw OLEDError.scriptCompile
        }
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let code = errorInfo[NSAppleScript.errorNumber] as? Int ?? 0
            if code == -1743 {
                throw OLEDError.notAuthorized
            }
            let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "AppleScript failed"
            throw OLEDError.script(message)
        }
        return result.stringValue ?? ""
    }
}

private enum OLEDError: Error {
    case scriptCompile
    case notAuthorized
    case script(String)
}
