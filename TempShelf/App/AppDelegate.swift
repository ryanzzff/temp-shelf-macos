import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: FloatingPanelController?
    private var dragMonitor: DragMonitor?
    private var hotKeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let shelfStore = ShelfStore.shared
        panelController = FloatingPanelController(shelfStore: shelfStore)
        dragMonitor = DragMonitor(onDragStarted: { [weak self] in
            Task { @MainActor in
                self?.panelController?.showPanel()
            }
        })
        dragMonitor?.start()
        setupHotKey()

        // Show shelf panel on launch so user sees something
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.panelController?.showPanel()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        dragMonitor?.stop()
        if let hotKeyMonitor {
            NSEvent.removeMonitor(hotKeyMonitor)
        }
    }

    private func setupHotKey() {
        hotKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 2 {
                Task { @MainActor in
                    self?.panelController?.togglePanel()
                }
            }
        }
    }

    func showPanel() {
        panelController?.showPanel()
    }

    func hidePanel() {
        panelController?.hidePanel()
    }

    func togglePanel() {
        panelController?.togglePanel()
    }
}
