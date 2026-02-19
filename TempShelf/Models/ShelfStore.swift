import AppKit
import Combine

@MainActor
final class ShelfStore: ObservableObject {
    static let shared = ShelfStore()

    @Published var items: [ShelfItem] = []
    @Published var selectedItemIDs: Set<UUID> = []

    var selectedItems: [ShelfItem] {
        items.filter { selectedItemIDs.contains($0.id) }
    }

    func addItems(from urls: [URL]) {
        for url in urls {
            guard !items.contains(where: { $0.url == url }) else { continue }
            var item = ShelfItem(url: url)
            items.append(item)

            Task {
                if let thumbnail = await item.generateThumbnail() {
                    if let index = items.firstIndex(where: { $0.id == item.id }) {
                        items[index].thumbnail = thumbnail
                    }
                }
            }
        }
    }

    func removeItem(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
        selectedItemIDs.remove(item.id)
    }

    func removeItems(_ itemsToRemove: [ShelfItem]) {
        let ids = Set(itemsToRemove.map(\.id))
        items.removeAll { ids.contains($0.id) }
        selectedItemIDs.subtract(ids)
    }

    func removeSelected() {
        removeItems(selectedItems)
    }

    func removeAll() {
        items.removeAll()
        selectedItemIDs.removeAll()
    }

    func selectAll() {
        selectedItemIDs = Set(items.map(\.id))
    }

    func clearSelection() {
        selectedItemIDs.removeAll()
    }

    func toggleSelection(_ item: ShelfItem) {
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    func selectOnly(_ item: ShelfItem) {
        selectedItemIDs = [item.id]
    }

    func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    var fileURLsForDrag: [URL] {
        let selected = selectedItems
        return selected.isEmpty ? items.map(\.url) : selected.map(\.url)
    }
}
