import AppKit

/// Handles drag-out: provides file URLs to the dragging pasteboard when items are dragged from the shelf.
class ShelfDragSource: NSObject, NSDraggingSource {
    private let shelfStore: ShelfStore
    private let urls: [URL]

    init(shelfStore: ShelfStore, urls: [URL]) {
        self.shelfStore = shelfStore
        self.urls = urls
        super.init()
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        switch context {
        case .outsideApplication:
            return [.copy, .move]
        case .withinApplication:
            return .move
        @unknown default:
            return .copy
        }
    }

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        // If Option key was held (move operation), remove items from shelf
        if operation == .move {
            Task { @MainActor in
                let itemsToRemove = shelfStore.items.filter { urls.contains($0.url) }
                shelfStore.removeItems(itemsToRemove)
            }
        }
    }

    /// Creates pasteboard items for dragging the given URLs.
    static func pasteboardItems(for urls: [URL]) -> [NSPasteboardItem] {
        urls.map { url in
            let item = NSPasteboardItem()
            item.setString(url.absoluteString, forType: .fileURL)
            return item
        }
    }

    /// Creates dragging items for a set of URLs.
    static func draggingItems(for urls: [URL]) -> [NSDraggingItem] {
        urls.map { url in
            let item = NSDraggingItem(pasteboardWriter: url as NSURL)
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 48, height: 48)
            item.setDraggingFrame(NSRect(origin: .zero, size: NSSize(width: 48, height: 48)), contents: icon)
            return item
        }
    }
}
