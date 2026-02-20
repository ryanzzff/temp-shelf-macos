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
        let isInsideApp = Self.isInsideApp(screenPoint: screenPoint)
        handleDragEnd(operation: operation, optionKeyHeld: NSEvent.modifierFlags.contains(.option), droppedInsideApp: isInsideApp)
    }

    /// Handles post-drag cleanup. When Option is held, trashes source files after a delay
    /// to allow Finder to finish copying. Removes dragged items from shelf on any successful operation.
    /// Drops back onto our own app are ignored.
    func handleDragEnd(operation: NSDragOperation, optionKeyHeld: Bool, droppedInsideApp: Bool = false) {
        guard operation != [], !droppedInsideApp else { return }
        if optionKeyHeld {
            let urlsToTrash = urls
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.sourceDeletionDelay) {
                Self.verifyAndTrashSourceFiles(urlsToTrash)
            }
        }
        Task { @MainActor in
            let itemsToRemove = shelfStore.items.filter { urls.contains($0.url) }
            shelfStore.removeItems(itemsToRemove)
        }
    }

    /// Delay before trashing source files, giving Finder time to complete the copy.
    static var sourceDeletionDelay: TimeInterval = 1.0

    /// Closure that finds files with the same name as the given URL.
    /// Injectable for testing. Default uses Spotlight.
    static var copyFinder: (URL, @escaping ([URL]) -> Void) -> Void = { url, completion in
        findCopiesViaSpotlight(for: url, completion: completion)
    }

    /// Returns true if the given screen point is inside any visible window of our app.
    static func isInsideApp(screenPoint: NSPoint) -> Bool {
        NSApp.windows.contains { $0.isVisible && $0.frame.contains(screenPoint) }
    }

    /// Spotlight query timeout before giving up and keeping the source file.
    static var spotlightTimeout: TimeInterval = 10.0

    /// Uses Spotlight to find files with the same name as `sourceURL` anywhere on disk.
    /// Uses a live query that waits for Spotlight to index newly copied files.
    static func findCopiesViaSpotlight(for sourceURL: URL, completion: @escaping ([URL]) -> Void) {
        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryLocalComputerScope]
        query.predicate = NSPredicate(format: "kMDItemFSName == %@", sourceURL.lastPathComponent)

        var gatherObserver: NSObjectProtocol?
        var updateObserver: NSObjectProtocol?
        var completed = false

        let extractURLs: () -> [URL] = {
            var urls: [URL] = []
            for i in 0..<query.resultCount {
                if let item = query.result(at: i) as? NSMetadataItem,
                   let path = item.value(forAttribute: kMDItemPath as String) as? String {
                    urls.append(URL(fileURLWithPath: path))
                }
            }
            return urls
        }

        let finish: ([URL]) -> Void = { urls in
            guard !completed else { return }
            completed = true
            query.stop()
            if let obs = gatherObserver { NotificationCenter.default.removeObserver(obs) }
            if let obs = updateObserver { NotificationCenter.default.removeObserver(obs) }
            completion(urls)
        }

        gatherObserver = NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidFinishGathering,
            object: query, queue: .main
        ) { _ in
            let urls = extractURLs()
            // If we found results beyond just the source itself, finish immediately
            if urls.contains(where: { $0 != sourceURL }) {
                finish(urls)
            } else {
                // Keep query running to catch newly indexed files
                query.enableUpdates()
            }
        }

        updateObserver = NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidUpdate,
            object: query, queue: .main
        ) { _ in
            query.disableUpdates()
            let urls = extractURLs()
            if urls.contains(where: { $0 != sourceURL }) {
                finish(urls)
            } else {
                query.enableUpdates()
            }
        }

        query.start()

        // Timeout — safe default: keep source
        DispatchQueue.main.asyncAfter(deadline: .now() + spotlightTimeout) {
            finish([])
        }
    }

    /// Verifies a matching copy exists before trashing each source file.
    /// If no matching copy is found (e.g. user clicked "Stop" on Finder's conflict dialog),
    /// the source file is kept to prevent data loss.
    ///
    /// Compares file size first (fast), then attempts full content comparison.
    /// In a sandboxed app the content read may fail for the destination file,
    /// in which case a size match alone is accepted — this is no worse than the
    /// pre-verification behavior which always trashed.
    static func verifyAndTrashSourceFiles(
        _ urls: [URL],
        using fileManager: FileManager = .default
    ) {
        for url in urls {
            copyFinder(url) { copies in
                let sourceSize = (try? fileManager.attributesOfItem(atPath: url.path))?[.size] as? UInt64
                for copy in copies where copy != url {
                    let destSize = (try? fileManager.attributesOfItem(atPath: copy.path))?[.size] as? UInt64
                    guard sourceSize == destSize else { continue }

                    // Try content comparison when both files are readable
                    if let sourceData = try? Data(contentsOf: url),
                       let destData = try? Data(contentsOf: copy) {
                        guard sourceData == destData else { continue }
                    }
                    // If content can't be read (e.g. sandbox), size match is sufficient

                    // Matching copy found — safe to trash
                    try? fileManager.trashItem(at: url, resultingItemURL: nil)
                    return
                }
                // No match — keep source
            }
        }
    }

    /// Moves the given source files to Trash. Recoverable if Finder's copy was cancelled.
    /// Errors are silently ignored (e.g. file already gone).
    static func deleteSourceFiles(_ urls: [URL], using fileManager: FileManager = .default) {
        for url in urls {
            try? fileManager.trashItem(at: url, resultingItemURL: nil)
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
