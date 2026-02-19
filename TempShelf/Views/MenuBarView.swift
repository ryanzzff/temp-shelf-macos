import SwiftUI

struct MenuBarView: View {
    @ObservedObject var shelfStore: ShelfStore

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if shelfStore.items.isEmpty {
                Text("Shelf is empty")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                Text("\(shelfStore.items.count) item\(shelfStore.items.count == 1 ? "" : "s") on shelf")
                    .font(.headline)
                    .padding(.horizontal)

                Divider()

                ForEach(shelfStore.items.prefix(10)) { item in
                    Button {
                        NSWorkspace.shared.open(item.url)
                    } label: {
                        HStack {
                            Image(nsImage: item.icon)
                                .resizable()
                                .frame(width: 16, height: 16)
                            Text(item.name)
                                .lineLimit(1)
                            Spacer()
                            Text(item.fileSizeFormatted)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }

                if shelfStore.items.count > 10 {
                    Text("+ \(shelfStore.items.count - 10) more...")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .padding(.horizontal)
                }
            }

            Divider()

            Button("Show Shelf") {
                if let delegate = NSApp.delegate as? AppDelegate {
                    delegate.showPanel()
                }
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            if !shelfStore.items.isEmpty {
                Button("Clear Shelf") {
                    shelfStore.removeAll()
                }
            }

            Divider()

            SettingsLink {
                Text("Settings...")
            }

            Button("Quit TempShelf") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(.vertical, 4)
    }
}
