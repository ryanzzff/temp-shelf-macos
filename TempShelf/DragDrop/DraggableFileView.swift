import AppKit
import SwiftUI

/// An NSView that initiates a proper NSDraggingSession for file URLs.
/// This uses the AppKit drag API directly so Finder and other apps can accept the drop.
class DraggableFileNSView: NSView, NSDraggingSource {
    var fileURLs: [URL] = []
    var dragImage: NSImage?
    var onDragCompleted: ((_ operation: NSDragOperation) -> Void)?
    private var mouseDownLocation: NSPoint?
    private var dragSessionStarted = false

    override var mouseDownCanMoveWindow: Bool { false }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        switch context {
        case .outsideApplication:
            return .copy
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
        dragSessionStarted = false
        guard operation != [] else { return }

        // Ignore drops back onto our own app (e.g. accidental drop on shelf)
        guard !ShelfDragSource.isInsideApp(screenPoint: screenPoint) else { return }

        if NSEvent.modifierFlags.contains(.option) {
            let urlsToTrash = fileURLs
            DispatchQueue.main.asyncAfter(deadline: .now() + ShelfDragSource.sourceDeletionDelay) {
                ShelfDragSource.verifyAndTrashSourceFiles(urlsToTrash)
            }
        }
        onDragCompleted?(operation)
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = convert(event.locationInWindow, from: nil)
        dragSessionStarted = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard !fileURLs.isEmpty, !dragSessionStarted else {
            return
        }

        guard let mouseDownLocation else {
            return
        }

        let currentLocation = convert(event.locationInWindow, from: nil)
        let dx = abs(currentLocation.x - mouseDownLocation.x)
        let dy = abs(currentLocation.y - mouseDownLocation.y)

        // Require a minimum drag distance to avoid accidental drags
        guard dx > 3 || dy > 3 else { return }

        dragSessionStarted = true

        // Create dragging items from file URLs using NSURL as pasteboard writer
        let draggingItems: [NSDraggingItem] = fileURLs.map { url in
            let item = NSDraggingItem(pasteboardWriter: url as NSURL)

            let icon = dragImage ?? NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 48, height: 48)
            item.setDraggingFrame(
                NSRect(origin: mouseDownLocation, size: NSSize(width: 48, height: 48)),
                contents: icon
            )
            return item
        }

        beginDraggingSession(with: draggingItems, event: event, source: self)
        self.mouseDownLocation = nil
    }

    override func mouseUp(with event: NSEvent) {
        mouseDownLocation = nil
        dragSessionStarted = false
        super.mouseUp(with: event)
    }
}

/// SwiftUI wrapper that makes its content draggable as file URLs via AppKit NSDraggingSession.
struct DraggableFileView<Content: View>: NSViewRepresentable {
    let fileURLs: [URL]
    let dragImage: NSImage?
    let onDragCompleted: ((_ operation: NSDragOperation) -> Void)?
    let content: Content

    init(
        fileURLs: [URL],
        dragImage: NSImage? = nil,
        onDragCompleted: ((_ operation: NSDragOperation) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.fileURLs = fileURLs
        self.dragImage = dragImage
        self.onDragCompleted = onDragCompleted
        self.content = content()
    }

    func makeNSView(context: Context) -> DraggableFileNSView {
        let dragView = DraggableFileNSView()

        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        dragView.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: dragView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: dragView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: dragView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: dragView.trailingAnchor),
        ])

        dragView.fileURLs = fileURLs
        dragView.dragImage = dragImage
        dragView.onDragCompleted = onDragCompleted
        return dragView
    }

    func updateNSView(_ nsView: DraggableFileNSView, context: Context) {
        nsView.fileURLs = fileURLs
        nsView.dragImage = dragImage
        nsView.onDragCompleted = onDragCompleted

        // Update the SwiftUI content
        if let hostingView = nsView.subviews.first as? NSHostingView<Content> {
            hostingView.rootView = content
        }
    }
}
