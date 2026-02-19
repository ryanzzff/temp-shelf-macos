import AppKit

/// Monitors for global drag events to auto-show the shelf when the user starts dragging.
class DragMonitor {
    private var eventMonitor: Any?
    private let onDragStarted: () -> Void
    private var isDragging = false

    init(onDragStarted: @escaping () -> Void) {
        self.onDragStarted = onDragStarted
    }

    func start() {
        // Default to true if never set (bool(forKey:) returns false for missing keys)
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "showOnDragStart") == nil {
            defaults.set(true, forKey: "showOnDragStart")
        }
        guard defaults.bool(forKey: "showOnDragStart") else { return }

        // Monitor for mouse dragged events globally
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDragged]
        ) { [weak self] event in
            guard let self, !self.isDragging else { return }

            // Detect drag start: mouse is being dragged with button held
            if event.type == .leftMouseDragged && event.buttonNumber == 0 {
                // Small threshold to avoid triggering on regular clicks
                let deltaX = abs(event.deltaX)
                let deltaY = abs(event.deltaY)
                if deltaX > 3 || deltaY > 3 {
                    self.isDragging = true
                    DispatchQueue.main.async {
                        self.onDragStarted()
                    }
                }
            }
        }

        // Monitor for mouse up to reset drag state
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            self?.isDragging = false
        }
    }

    func stop() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
    }
}
