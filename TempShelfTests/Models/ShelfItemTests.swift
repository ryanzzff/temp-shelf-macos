import XCTest
import UniformTypeIdentifiers
@testable import TempShelf

final class ShelfItemTests: XCTestCase {
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

    // MARK: - init

    func testInitSetsURL() throws {
        let url = try TestFileHelper.createFile(named: "hello.txt", in: testDir)
        let item = ShelfItem(url: url)
        XCTAssertEqual(item.url, url)
    }

    func testInitSetsNameFromLastPathComponent() throws {
        let url = try TestFileHelper.createFile(named: "hello.txt", in: testDir)
        let item = ShelfItem(url: url)
        XCTAssertEqual(item.name, "hello.txt")
    }

    func testInitSetsDateAdded() throws {
        let before = Date()
        let item = try ShelfItemFactory.makeItem(named: "a.txt", in: testDir)
        let after = Date()
        XCTAssertGreaterThanOrEqual(item.dateAdded, before)
        XCTAssertLessThanOrEqual(item.dateAdded, after)
    }

    func testInitGeneratesUniqueIDs() throws {
        let item1 = try ShelfItemFactory.makeItem(named: "a.txt", in: testDir)
        let item2 = try ShelfItemFactory.makeItem(named: "b.txt", in: testDir)
        XCTAssertNotEqual(item1.id, item2.id)
    }

    func testInitReadsFileSize() throws {
        let data = Data(repeating: 0x42, count: 256)
        let item = try ShelfItemFactory.makeItem(named: "sized.txt", in: testDir, contents: data)
        XCTAssertEqual(item.fileSize, 256)
    }

    func testInitReadsFileSizeForLargerFile() throws {
        let item = try ShelfItemFactory.makeItem(named: "big.bin", in: testDir, size: 10_000)
        XCTAssertEqual(item.fileSize, 10_000)
    }

    func testInitSetsIconNonNil() throws {
        let item = try ShelfItemFactory.makeItem(named: "a.txt", in: testDir)
        XCTAssertNotNil(item.icon)
    }

    func testInitSetsThumbnailToNil() throws {
        let item = try ShelfItemFactory.makeItem(named: "a.txt", in: testDir)
        XCTAssertNil(item.thumbnail)
    }

    func testInitSetsFileType() throws {
        let url = try TestFileHelper.createFile(named: "test.txt", in: testDir)
        let item = ShelfItem(url: url)
        XCTAssertNotNil(item.fileType)
    }

    // MARK: - isDirectory

    func testIsDirectoryForFile() throws {
        let item = try ShelfItemFactory.makeItem(named: "file.txt", in: testDir)
        XCTAssertFalse(item.isDirectory)
    }

    func testIsDirectoryForDirectory() throws {
        let item = try ShelfItemFactory.makeDirectoryItem(named: "MyFolder", in: testDir)
        XCTAssertTrue(item.isDirectory)
    }

    // MARK: - fileSizeFormatted

    func testFileSizeFormattedZeroBytes() throws {
        let item = try ShelfItemFactory.makeItem(named: "empty.txt", in: testDir, size: 0)
        XCTAssertEqual(item.fileSizeFormatted, "Zero KB")
    }

    func testFileSizeFormattedNonZero() throws {
        let item = try ShelfItemFactory.makeItem(named: "data.bin", in: testDir, size: 1024)
        let formatted = item.fileSizeFormatted
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertTrue(formatted.contains("KB") || formatted.contains("bytes"))
    }

    // MARK: - Equatable

    func testEqualityByID() throws {
        let item1 = try ShelfItemFactory.makeItem(named: "a.txt", in: testDir)
        var item2 = item1
        // Same id means equal, even if we mutate a stored property
        item2.thumbnail = NSImage()
        XCTAssertEqual(item1, item2)
    }

    func testInequalityForDifferentIDs() throws {
        let item1 = try ShelfItemFactory.makeItem(named: "a.txt", in: testDir)
        let item2 = try ShelfItemFactory.makeItem(named: "b.txt", in: testDir)
        XCTAssertNotEqual(item1, item2)
    }

    // MARK: - Hashable

    func testHashableConsistentWithEquatable() throws {
        let item = try ShelfItemFactory.makeItem(named: "a.txt", in: testDir)
        var copy = item
        copy.thumbnail = NSImage()
        // Equal items must have equal hashes
        XCTAssertEqual(item.hashValue, copy.hashValue)
    }

    func testHashableCanBeUsedInSet() throws {
        let items = try ShelfItemFactory.makeItems(count: 5, in: testDir)
        let set = Set(items)
        XCTAssertEqual(set.count, 5)
    }
}
