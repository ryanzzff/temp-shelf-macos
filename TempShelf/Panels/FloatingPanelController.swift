import AppKit
import SwiftUI

/// Manages the floating shelf panel lifecycle: showing, hiding, positioning.
@MainActor
class FloatingPanelController {
    private var panel: FloatingPanel?
    private let shelfStore: ShelfStore
    private var autoHideTimer: Timer?

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    init(shelfStore: ShelfStore) {
        self.shelfStore = shelfStore
    }

    func showPanel() {
        if panel == nil {
            createPanel()
        }

        guard let panel else { return }

        positionPanel(panel)
        panel.makeKeyAndOrderFront(nil)
        panel.alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel.animator().alphaValue = 1
        }

        cancelAutoHide()
    }

    func hidePanel() {
        guard let panel, panel.isVisible else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.panel?.orderOut(nil)
        })
    }

    func togglePanel() {
        if isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    func scheduleAutoHide(delay: TimeInterval = 2.0) {
        guard delay > 0 else { return }
        cancelAutoHide()
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.hidePanel()
            }
        }
    }

    func cancelAutoHide() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }

    private func createPanel() {
        let panelRect = NSRect(x: 0, y: 0, width: 280, height: 400)
        let panel = FloatingPanel(contentRect: panelRect)

        let shelfView = ShelfContentView(shelfStore: shelfStore, panelController: self)
        let hostingView = NSHostingView(rootView: shelfView)
        hostingView.frame = panelRect

        // Wrap in a ShelfDropView (NSVisualEffectView subclass) for vibrancy + drop support
        let dropView = ShelfDropView(frame: panelRect)
        dropView.material = .hudWindow
        dropView.state = .active
        dropView.blendingMode = .behindWindow
        dropView.wantsLayer = true
        dropView.layer?.cornerRadius = 12
        dropView.layer?.masksToBounds = true

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        dropView.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: dropView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: dropView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: dropView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: dropView.trailingAnchor),
        ])

        panel.contentView = dropView

        // Set up drag destination
        let dropHandler = ShelfDropHandler(shelfStore: shelfStore, panelController: self)
        dropView.registerForDraggedTypes(ShelfDropHandler.acceptedTypes)
        dropView.dropHandler = dropHandler

        self.panel = panel
    }

    private func positionPanel(_ panel: FloatingPanel) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size

        let shelfPosition = UserDefaults.standard.string(forKey: "shelfPosition") ?? "right"

        let origin: NSPoint
        switch shelfPosition {
        case "left":
            origin = NSPoint(
                x: screenFrame.minX + 16,
                y: screenFrame.midY - panelSize.height / 2
            )
        case "cursor":
            let mouseLocation = NSEvent.mouseLocation
            origin = NSPoint(
                x: min(mouseLocation.x + 20, screenFrame.maxX - panelSize.width - 16),
                y: min(mouseLocation.y - panelSize.height / 2, screenFrame.maxY - panelSize.height - 16)
            )
        default: // "right"
            origin = NSPoint(
                x: screenFrame.maxX - panelSize.width - 16,
                y: screenFrame.midY - panelSize.height / 2
            )
        }

        panel.setFrameOrigin(origin)
    }
}
