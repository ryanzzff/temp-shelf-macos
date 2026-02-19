import AppKit
import Quartz

/// Manages Quick Look preview panel for shelf items.
@MainActor
class QuickLookCoordinator: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = QuickLookCoordinator()

    var previewItems: [URL] = []
    var currentIndex: Int = 0

    func showPreview(for urls: [URL], at index: Int = 0) {
        previewItems = urls
        currentIndex = min(index, urls.count - 1)

        guard let panel = QLPreviewPanel.shared() else { return }

        if panel.isVisible {
            panel.reloadData()
        } else {
            panel.makeKeyAndOrderFront(nil)
        }
    }

    func togglePreview(for urls: [URL], at index: Int = 0) {
        guard let panel = QLPreviewPanel.shared() else { return }

        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            showPreview(for: urls, at: index)
        }
    }

    // MARK: - QLPreviewPanelDataSource

    nonisolated func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        MainActor.assumeIsolated {
            previewItems.count
        }
    }

    nonisolated func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        MainActor.assumeIsolated {
            previewItems[index] as NSURL
        }
    }

    // MARK: - QLPreviewPanelDelegate

    nonisolated func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        return false
    }
}
