import SwiftUI

struct SettingsView: View {
    @AppStorage("showOnDragStart") private var showOnDragStart = true
    @AppStorage("autoHideDelay") private var autoHideDelay = 2.0
    @AppStorage("shelfPosition") private var shelfPosition = "right"

    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Show shelf when drag starts", isOn: $showOnDragStart)
                Picker("Auto-hide delay", selection: $autoHideDelay) {
                    Text("1 second").tag(1.0)
                    Text("2 seconds").tag(2.0)
                    Text("5 seconds").tag(5.0)
                    Text("Never").tag(0.0)
                }
            }

            Section("Appearance") {
                Picker("Shelf position", selection: $shelfPosition) {
                    Text("Right edge").tag("right")
                    Text("Left edge").tag("left")
                    Text("Near cursor").tag("cursor")
                }
            }

            Section("Keyboard Shortcut") {
                Text("Toggle Shelf: Cmd + Shift + D")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 300)
    }
}
