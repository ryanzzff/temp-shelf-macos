import AppKit

/// Handles drag-in: accepts files, folders, images, URLs, and text dropped onto the shelf.
class ShelfDropHandler: NSObject {
    static let acceptedTypes: [NSPasteboard.PasteboardType] = [
        .fileURL,
        .URL,
        .string,
        .tiff,
        .png,
    ]

    private let shelfStore: ShelfStore
    private let panelController: FloatingPanelController

    init(shelfStore: ShelfStore, panelController: FloatingPanelController) {
        self.shelfStore = shelfStore
        self.panelController = panelController
        super.init()
    }

    func attachTo(view: NSView) {
        // We use a custom subclass to handle dragging protocol
        if let dropView = view as? ShelfDropView {
            dropView.dropHandler = self
        }
    }

    func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        let pasteboard = sender.draggingPasteboard

        if pasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) {
            return .copy
        }

        if pasteboard.types?.contains(.fileURL) == true ||
           pasteboard.types?.contains(.URL) == true {
            return .copy
        }

        return .copy
    }

    func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard

        // Try to read file URLs first
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
            Task { @MainActor in
                self.shelfStore.addItems(from: urls)
                self.panelController.cancelAutoHide()
            }
            return true
        }

        // Try regular URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            Task { @MainActor in
                self.shelfStore.addItems(from: urls)
                self.panelController.cancelAutoHide()
            }
            return true
        }

        return false
    }
}

/// NSView subclass that implements NSDraggingDestination for the shelf panel.
class ShelfDropView: NSVisualEffectView {
    var dropHandler: ShelfDropHandler?
    private var isDragOver = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        // Reject drops from within our own app (prevents shelf items being removed and re-added)
        if sender.draggingSource != nil { return [] }
        isDragOver = true
        needsDisplay = true
        return dropHandler?.draggingEntered(sender) ?? .copy
    }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        isDragOver = false
        needsDisplay = true
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        if sender.draggingSource != nil { return [] }
        return .copy
    }

    override func prepareForDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        return true
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        isDragOver = false
        needsDisplay = true
        return dropHandler?.performDragOperation(sender) ?? false
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if isDragOver {
            NSColor.controlAccentColor.withAlphaComponent(0.2).setFill()
            let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 4), xRadius: 8, yRadius: 8)
            path.fill()

            NSColor.controlAccentColor.withAlphaComponent(0.5).setStroke()
            path.lineWidth = 2
            path.setLineDash([6, 3], count: 2, phase: 0)
            path.stroke()
        }
    }
}
