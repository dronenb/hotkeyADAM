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
    }
}
