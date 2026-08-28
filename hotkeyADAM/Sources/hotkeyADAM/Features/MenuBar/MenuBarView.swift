import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appModel: HotkeyAdamAppModel

    var body: some View {
        Text("hotkeyADAM")
            .font(.headline)
            .padding(.vertical, 4)

        Divider()

        if appModel.isAccessibilityGranted {
            Button("Open Shortcuts…") {
                // Shortcuts browser arrives in a later phase.
            }
        } else {
            Button("Enable Accessibility…") {
                appModel.requestAccessibility()
            }
        }

        Divider()

        Button("Quit hotkeyADAM") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
