import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appModel: HotkeyAdamAppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text("hotkeyADAM")
            .font(.headline)
            .padding(.vertical, 4)

        Divider()

        if appModel.isAccessibilityGranted {
            Button("Open Shortcuts…") {
                openWindow(id: "shortcuts")
            }
        } else {
            Button("Enable Accessibility…") {
                appModel.requestAccessibility()
            }
        }

        Button("Import Profile…") {
            openWindow(id: "import-profile")
        }

        Divider()

        Button("Quit hotkeyADAM") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
