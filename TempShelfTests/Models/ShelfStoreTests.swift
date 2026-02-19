import XCTest
@testable import TempShelf

@MainActor
final class ShelfStoreTests: XCTestCase {
    private var store: ShelfStore!
    private var testDir: URL!

    override func setUp() async throws {
        try await super.setUp()
        store = ShelfStore()
        testDir = try TestFileHelper.makeTestDirectory()
    }

    override func tearDown() async throws {
        TestFileHelper.cleanup(directory: testDir)
        store = nil
        testDir = nil
        try await super.tearDown()
    }

    // MARK: - Initial State

    func testInitialItemsIsEmpty() {
        XCTAssertTrue(store.items.isEmpty)
    }

    func testInitialSelectedIDsIsEmpty() {
        XCTAssertTrue(store.selectedItemIDs.isEmpty)
    }

    func testInitialSelectedItemsIsEmpty() {
        XCTAssertTrue(store.selectedItems.isEmpty)
    }

    // MARK: - addItems

    func testAddSingleItem() throws {
        let url = try TestFileHelper.createFile(named: "a.txt", in: testDir)
        store.addItems(from: [url])
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.url, url)
    }

    func testAddMultipleItems() throws {
        let url1 = try TestFileHelper.createFile(named: "a.txt", in: testDir)
        let url2 = try TestFileHelper.createFile(named: "b.txt", in: testDir)
        store.addItems(from: [url1, url2])
        XCTAssertEqual(store.items.count, 2)
    }

    func testAddDuplicateURLIsIgnored() throws {
        let url = try TestFileHelper.createFile(named: "a.txt", in: testDir)
        store.addItems(from: [url])
        store.addItems(from: [url])
        XCTAssertEqual(store.items.count, 1)
    }

    func testAddDuplicateInSameBatchIsIgnored() throws {
        let url = try TestFileHelper.createFile(named: "a.txt", in: testDir)
        store.addItems(from: [url, url])
        XCTAssertEqual(store.items.count, 1)
    }

    func testAddPreservesInsertionOrder() throws {
        let urls = try (0..<5).map { i in
            try TestFileHelper.createFile(named: "file\(i).txt", in: testDir)
        }
        store.addItems(from: urls)
        XCTAssertEqual(store.items.map(\.url), urls)
    }

    // MARK: - removeItem

    func testRemoveSingleItem() throws {
        let item = try ShelfItemFactory.makeItem(named: "a.txt", in: testDir)
        store.items = [item]
        store.removeItem(item)
        XCTAssertTrue(store.items.isEmpty)
    }

    func testRemoveItemClearsItsSelection() throws {
        let item = try ShelfItemFactory.makeItem(named: "a.txt", in: testDir)
        store.items = [item]
        store.selectedItemIDs = [item.id]
        store.removeItem(item)
        XCTAssertFalse(store.selectedItemIDs.contains(item.id))
    }

    func testRemoveItemLeavesOtherItems() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        store.removeItem(items[1])
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items.map(\.id), [items[0].id, items[2].id])
    }

    // MARK: - removeItems

    func testRemoveMultipleItems() throws {
        let items = try ShelfItemFactory.makeItems(count: 4, in: testDir)
        store.items = items
        store.removeItems([items[0], items[2]])
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items.map(\.id), [items[1].id, items[3].id])
    }

    func testRemoveItemsClearsSelectionOfRemoved() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        store.selectedItemIDs = Set(items.map(\.id))
        store.removeItems([items[0], items[2]])
        XCTAssertEqual(store.selectedItemIDs, [items[1].id])
    }

    // MARK: - removeSelected

    func testRemoveSelectedRemovesOnlySelected() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        store.selectedItemIDs = [items[1].id]
        store.removeSelected()
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items.map(\.id), [items[0].id, items[2].id])
    }

    func testRemoveSelectedWhenNoneSelected() throws {
        let items = try ShelfItemFactory.makeItems(count: 2, in: testDir)
        store.items = items
        store.removeSelected()
        XCTAssertEqual(store.items.count, 2)
    }

    // MARK: - removeAll

    func testRemoveAllClearsItems() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        store.removeAll()
        XCTAssertTrue(store.items.isEmpty)
    }

    func testRemoveAllClearsSelection() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        store.selectedItemIDs = Set(items.map(\.id))
        store.removeAll()
        XCTAssertTrue(store.selectedItemIDs.isEmpty)
    }

    // MARK: - selectAll

    func testSelectAllSelectsEveryItem() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        store.selectAll()
        XCTAssertEqual(store.selectedItemIDs, Set(items.map(\.id)))
    }

    func testSelectAllOnEmptyStoreIsNoOp() {
        store.selectAll()
        XCTAssertTrue(store.selectedItemIDs.isEmpty)
    }

    // MARK: - clearSelection

    func testClearSelectionDeselectsAll() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        store.selectedItemIDs = Set(items.map(\.id))
        store.clearSelection()
        XCTAssertTrue(store.selectedItemIDs.isEmpty)
    }

    // MARK: - toggleSelection

    func testToggleSelectionSelectsUnselectedItem() throws {
        let item = try ShelfItemFactory.makeItem(named: "a.txt", in: testDir)
        store.items = [item]
        store.toggleSelection(item)
        XCTAssertTrue(store.selectedItemIDs.contains(item.id))
    }

    func testToggleSelectionDeselectsSelectedItem() throws {
        let item = try ShelfItemFactory.makeItem(named: "a.txt", in: testDir)
        store.items = [item]
        store.selectedItemIDs = [item.id]
        store.toggleSelection(item)
        XCTAssertFalse(store.selectedItemIDs.contains(item.id))
    }

    func testToggleSelectionDoesNotAffectOthers() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        store.selectedItemIDs = [items[0].id]
        store.toggleSelection(items[1])
        XCTAssertEqual(store.selectedItemIDs, [items[0].id, items[1].id])
    }

    // MARK: - selectOnly

    func testSelectOnlySetsExactlyOneItem() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        store.selectedItemIDs = Set(items.map(\.id))
        store.selectOnly(items[1])
        XCTAssertEqual(store.selectedItemIDs, [items[1].id])
    }

    func testSelectOnlyFromEmptySelection() throws {
        let item = try ShelfItemFactory.makeItem(named: "a.txt", in: testDir)
        store.items = [item]
        store.selectOnly(item)
        XCTAssertEqual(store.selectedItemIDs, [item.id])
    }

    // MARK: - selectedItems

    func testSelectedItemsReturnsMatchingItems() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        store.selectedItemIDs = [items[0].id, items[2].id]
        let selected = store.selectedItems
        XCTAssertEqual(selected.count, 2)
        XCTAssertEqual(Set(selected.map(\.id)), [items[0].id, items[2].id])
    }

    // MARK: - moveItem

    func testMoveItemFromFirstToLast() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        store.moveItem(from: IndexSet(integer: 0), to: 3)
        XCTAssertEqual(store.items.map(\.id), [items[1].id, items[2].id, items[0].id])
    }

    func testMoveItemFromLastToFirst() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        store.moveItem(from: IndexSet(integer: 2), to: 0)
        XCTAssertEqual(store.items.map(\.id), [items[2].id, items[0].id, items[1].id])
    }

    func testMoveItemSamePosition() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        let originalOrder = items.map(\.id)
        store.moveItem(from: IndexSet(integer: 1), to: 1)
        XCTAssertEqual(store.items.map(\.id), originalOrder)
    }

    // MARK: - fileURLsForDrag

    func testFileURLsForDragReturnsSelectedWhenSelected() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        store.selectedItemIDs = [items[1].id]
        XCTAssertEqual(store.fileURLsForDrag, [items[1].url])
    }

    func testFileURLsForDragReturnsAllWhenNoneSelected() throws {
        let items = try ShelfItemFactory.makeItems(count: 3, in: testDir)
        store.items = items
        XCTAssertEqual(store.fileURLsForDrag, items.map(\.url))
    }

    func testFileURLsForDragEmptyStore() {
        XCTAssertTrue(store.fileURLsForDrag.isEmpty)
    }
}
