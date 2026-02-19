import SwiftUI

@main
struct TempShelfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var shelfStore = ShelfStore.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(shelfStore: shelfStore)
        } label: {
            Image(systemName: shelfStore.items.isEmpty ? "tray" : "tray.full")
        }

        Settings {
            SettingsView()
        }
    }
}
