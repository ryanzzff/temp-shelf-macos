import XCTest
import AppKit
@testable import TempShelf

final class ShelfDragSourceTests: XCTestCase {
    private var testDir: URL!

    override func setUp() async throws {
        try await super.setUp()
        testDir = try TestFileHelper.makeTestDirectory()
    }

    override func tearDown() async throws {
        TestFileHelper.cleanup(directory: testDir)
        testDir = nil
        try await super.tearDown()
    }

    // MARK: - pasteboardItems

    func testPasteboardItemsCountMatchesURLs() throws {
        let urls = try (0..<3).map {
            try TestFileHelper.createFile(named: "file\($0).txt", in: testDir)
        }
        let items = ShelfDragSource.pasteboardItems(for: urls)
        XCTAssertEqual(items.count, 3)
    }

    func testPasteboardItemsContainFileURLType() throws {
        let url = try TestFileHelper.createFile(named: "a.txt", in: testDir)
        let items = ShelfDragSource.pasteboardItems(for: [url])
        let value = items.first?.string(forType: .fileURL)
        XCTAssertNotNil(value)
    }

    func testPasteboardItemsContainCorrectURL() throws {
        let url = try TestFileHelper.createFile(named: "a.txt", in: testDir)
        let items = ShelfDragSource.pasteboardItems(for: [url])
        let value = items.first?.string(forType: .fileURL)
        XCTAssertEqual(value, url.absoluteString)
    }

    func testPasteboardItemsEmptyInput() {
        let items = ShelfDragSource.pasteboardItems(for: [])
        XCTAssertTrue(items.isEmpty)
    }

    // MARK: - draggingItems

    func testDraggingItemsCountMatchesURLs() throws {
        let urls = try (0..<2).map {
            try TestFileHelper.createFile(named: "file\($0).txt", in: testDir)
        }
        let items = ShelfDragSource.draggingItems(for: urls)
        XCTAssertEqual(items.count, 2)
    }

    func testDraggingItemsEmptyInput() {
        let items = ShelfDragSource.draggingItems(for: [])
        XCTAssertTrue(items.isEmpty)
    }

    func testDraggingItemsHaveDraggingFrame() throws {
        let url = try TestFileHelper.createFile(named: "a.txt", in: testDir)
        let items = ShelfDragSource.draggingItems(for: [url])
        let frame = items.first?.draggingFrame
        XCTAssertNotNil(frame)
        XCTAssertEqual(frame?.width, 48)
        XCTAssertEqual(frame?.height, 48)
    }

    func testDraggingItemsHaveImageContents() throws {
        let url = try TestFileHelper.createFile(named: "a.txt", in: testDir)
        let items = ShelfDragSource.draggingItems(for: [url])
        XCTAssertNotNil(items.first?.imageComponentsProvider)
    }
}
