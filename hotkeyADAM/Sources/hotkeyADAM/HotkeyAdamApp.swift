import SwiftUI

@main
struct HotkeyAdamApp: App {
    @StateObject private var appModel = HotkeyAdamAppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appModel)
        } label: {
            Image(systemName: "keyboard")
        }
        .menuBarExtraStyle(.menu)

        Window("Shortcuts", id: "shortcuts") {
            ShortcutsBrowserView()
                .environmentObject(appModel)
                .frame(minWidth: 360, minHeight: 320)
        }

        Window("Import Profile", id: "import-profile") {
            ProfileImportView { url in
                try appModel.importProfile(from: url)
            }
            .environmentObject(appModel)
        }
    }
}
