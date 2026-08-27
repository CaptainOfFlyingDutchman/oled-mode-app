import SwiftUI

struct ControlDeckView: View {
    @EnvironmentObject private var controller: OLEDController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            goldRule
            powerBank
            goldRule
            menuBarBank
            channelRow(
                title: "DOCK",
                caption: "AUTOHIDE",
                ledOn: controller.dockHidden,
                offline: false,
                latched: controller.dockHidden,
                action: { controller.toggleDockHidden() }
            )
            channelRow(
                title: "STAGE STRIP",
                caption: controller.stageManagerEnabled ? "RECENT APPS" : "OFFLINE",
                ledOn: controller.stageHidden && controller.stageManagerEnabled,
                offline: !controller.stageManagerEnabled,
                latched: controller.stageHidden && controller.stageManagerEnabled,
                action: { controller.toggleStageHidden() }
            )
            goldRule
            footer
        }
        .padding(.horizontal, 22)
        .padding(.top, 0)
        .padding(.bottom, 16)
        .frame(width: 448)
        .fixedSize(horizontal: true, vertical: true)
        .background {
            ZStack {
                chassis
                scanlines
            }
        }
        .background(DeckSizeReporter())
        .ignoresSafeArea(.container, edges: .top)
        .preferredColorScheme(.dark)
        .onAppear { controller.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            controller.refresh()
        }
    }

    private var chassis: some View {
        Rectangle()
            .fill(DeckTheme.chassis)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.06), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 70)
            }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Color.clear
                .frame(width: 56, height: 1)
            Text("◈")
                .font(DeckTheme.hudFont(13, weight: .bold))
                .foregroundStyle(DeckTheme.amber)
            Text("OLED MODE")
                .font(DeckTheme.hudFont(13, weight: .heavy))
                .tracking(2.4)
                .foregroundStyle(DeckTheme.text)
            Spacer()
            Text("SYS.01")
                .font(DeckTheme.hudFont(10, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(DeckTheme.textDim)
        }
        .frame(height: 28)
    }

    private var goldRule: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        DeckTheme.amber.opacity(0.85),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }

    private var powerBank: some View {
        LatchButton(
            title: "POWER",
            subtitle: controller.isPresetActive ? "OLED ON" : "OLED OFF",
            isLatched: controller.isPresetActive,
            isPower: true,
            action: { controller.togglePower() }
        )
    }

    private var menuBarBank: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("MENU BAR")
            HStack(spacing: 8) {
                ForEach(MenuBarMode.allCases, id: \.self) { mode in
                    LatchButton(
                        title: mode.buttonTitle,
                        isLatched: controller.menuBarMode == mode,
                        action: { controller.setMenuBarMode(mode) }
                    )
                }
            }
        }
    }

    private func channelRow(
        title: String,
        caption: String,
        ledOn: Bool,
        offline: Bool,
        latched: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(DeckTheme.hudFont(12, weight: .heavy))
                    .tracking(1.6)
                    .foregroundStyle(offline ? DeckTheme.textDim : DeckTheme.text)
                Text(caption)
                    .font(DeckTheme.hudFont(9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(DeckTheme.textDim)
            }
            Spacer()
            StatusLED(isOn: ledOn, isOffline: offline)
            LatchButton(
                title: "HIDE",
                isLatched: latched,
                isEnabled: !offline,
                action: action
            )
            .frame(width: 108)
        }
        .padding(.horizontal, 4)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DeckTheme.hudFont(10, weight: .bold))
            .tracking(2)
            .foregroundStyle(DeckTheme.textDim)
    }

    private var footer: some View {
        HStack {
            Circle()
                .fill(controller.automationDenied ? DeckTheme.danger : DeckTheme.amber)
                .frame(width: 6, height: 6)
                .shadow(
                    color: (controller.automationDenied ? DeckTheme.danger : DeckTheme.amber).opacity(0.8),
                    radius: 4
                )
            Text(controller.footerText)
                .font(DeckTheme.hudFont(9, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(controller.automationDenied ? DeckTheme.danger : DeckTheme.textDim)
            Spacer()
        }
    }

    private var scanlines: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                var path = Path()
                path.addRect(CGRect(x: 0, y: y, width: size.width, height: 1))
                context.fill(path, with: .color(Color.black.opacity(0.10)))
                y += 3
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ControlDeckView()
        .environmentObject(OLEDController())
}
