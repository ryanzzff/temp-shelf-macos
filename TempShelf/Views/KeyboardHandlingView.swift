import AppKit
import SwiftUI

/// NSView that captures keyboard events for shelf navigation.
class KeyboardHandlingNSView: NSView {
    var onKeyDown: ((NSEvent) -> Bool)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if let handler = onKeyDown, handler(event) {
            return
        }
        super.keyDown(with: event)
    }
}

/// SwiftUI wrapper for keyboard event handling in the shelf.
struct KeyboardHandlingView: NSViewRepresentable {
    let shelfStore: ShelfStore

    func makeNSView(context: Context) -> KeyboardHandlingNSView {
        let view = KeyboardHandlingNSView()
        view.onKeyDown = { event in
            handleKeyEvent(event)
        }
        return view
    }

    func updateNSView(_ nsView: KeyboardHandlingNSView, context: Context) {
        nsView.onKeyDown = { event in
            handleKeyEvent(event)
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let items = shelfStore.items
        guard !items.isEmpty else { return false }

        switch event.keyCode {
        case 125: // Down arrow
            moveSelection(by: 1)
            return true
        case 126: // Up arrow
            moveSelection(by: -1)
            return true
        case 36: // Enter - open selected items
            openSelected()
            return true
        case 51, 117: // Delete / Forward Delete - remove selected
            removeSelected()
            return true
        case 49: // Space - Quick Look
            quickLookSelected()
            return true
        default:
            break
        }

        // Cmd+A - select all
        if event.modifierFlags.contains(.command) && event.keyCode == 0 {
            shelfStore.selectAll()
            return true
        }

        // Cmd+C - copy path
        if event.modifierFlags.contains(.command) && event.keyCode == 8 {
            copySelectedPaths()
            return true
        }

        return false
    }

    private func moveSelection(by offset: Int) {
        let items = shelfStore.items
        guard !items.isEmpty else { return }

        if shelfStore.selectedItemIDs.isEmpty {
            shelfStore.selectOnly(items[0])
            return
        }

        // Find the current focused item index
        if let lastSelected = items.last(where: { shelfStore.selectedItemIDs.contains($0.id) }),
           let currentIndex = items.firstIndex(where: { $0.id == lastSelected.id }) {
            let newIndex = max(0, min(items.count - 1, currentIndex + offset))
            shelfStore.selectOnly(items[newIndex])
        }
    }

    private func openSelected() {
        for item in shelfStore.selectedItems {
            NSWorkspace.shared.open(item.url)
        }
    }

    private func removeSelected() {
        withAnimation(.easeInOut(duration: 0.2)) {
            shelfStore.removeSelected()
        }
    }

    private func quickLookSelected() {
        let urls = shelfStore.selectedItems.map(\.url)
        guard !urls.isEmpty else { return }
        QuickLookCoordinator.shared.togglePreview(for: urls)
    }

    private func copySelectedPaths() {
        let paths = shelfStore.selectedItems.map(\.url.path)
        guard !paths.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(paths.joined(separator: "\n"), forType: .string)
    }
}
