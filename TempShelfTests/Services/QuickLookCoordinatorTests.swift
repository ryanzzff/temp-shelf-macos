import XCTest
@testable import TempShelf

@MainActor
final class QuickLookCoordinatorTests: XCTestCase {
    private var coordinator: QuickLookCoordinator!
    private var testDir: URL!

    override func setUp() async throws {
        try await super.setUp()
        coordinator = QuickLookCoordinator()
        testDir = try TestFileHelper.makeTestDirectory()
    }

    override func tearDown() async throws {
        TestFileHelper.cleanup(directory: testDir)
        coordinator = nil
        testDir = nil
        try await super.tearDown()
    }

    // MARK: - Initial State

    func testInitialPreviewItemsIsEmpty() {
        XCTAssertTrue(coordinator.previewItems.isEmpty)
    }

    func testInitialCurrentIndexIsZero() {
        XCTAssertEqual(coordinator.currentIndex, 0)
    }

    // MARK: - showPreview

    func testShowPreviewSetsPreviewItems() throws {
        let url = try TestFileHelper.createFile(named: "a.txt", in: testDir)
        coordinator.showPreview(for: [url])
        XCTAssertEqual(coordinator.previewItems, [url])
    }

    func testShowPreviewSetsCurrentIndex() throws {
        let urls = try (0..<3).map {
            try TestFileHelper.createFile(named: "file\($0).txt", in: testDir)
        }
        coordinator.showPreview(for: urls, at: 1)
        XCTAssertEqual(coordinator.currentIndex, 1)
    }

    func testShowPreviewClampsIndexToLastItem() throws {
        let url = try TestFileHelper.createFile(named: "a.txt", in: testDir)
        coordinator.showPreview(for: [url], at: 10)
        XCTAssertEqual(coordinator.currentIndex, 0)
    }

    func testShowPreviewOverwritesPreviousItems() throws {
        let url1 = try TestFileHelper.createFile(named: "a.txt", in: testDir)
        let url2 = try TestFileHelper.createFile(named: "b.txt", in: testDir)
        coordinator.showPreview(for: [url1])
        coordinator.showPreview(for: [url2])
        XCTAssertEqual(coordinator.previewItems, [url2])
    }

    // MARK: - Data Source

    func testNumberOfPreviewItems() throws {
        let urls = try (0..<3).map {
            try TestFileHelper.createFile(named: "file\($0).txt", in: testDir)
        }
        coordinator.previewItems = urls
        let count = coordinator.numberOfPreviewItems(in: nil)
        XCTAssertEqual(count, 3)
    }

    func testPreviewItemAtIndex() throws {
        let url = try TestFileHelper.createFile(named: "a.txt", in: testDir)
        coordinator.previewItems = [url]
        let item = coordinator.previewPanel(nil, previewItemAt: 0) as? NSURL
        XCTAssertEqual(item as URL?, url)
    }
}
