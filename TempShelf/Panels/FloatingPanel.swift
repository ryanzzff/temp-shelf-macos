import AppKit

/// A custom NSPanel that floats above other windows and doesn't steal focus.
class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Floating behavior
        level = .floating
        isFloatingPanel = true
        hidesOnDeactivate = false

        // Visual style
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        // Disabled: this intercepts ALL drags including item drag-out
        isMovableByWindowBackground = false
        backgroundColor = .clear
        isOpaque = false

        // Content hugging
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Animation
        animationBehavior = .utilityWindow
    }
}

/// An NSView that allows dragging the window when placed in a specific region (e.g. the header).
class WindowDragView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
