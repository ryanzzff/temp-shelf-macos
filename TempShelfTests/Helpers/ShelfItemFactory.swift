import Foundation
@testable import TempShelf

/// Factory for creating ShelfItem instances backed by real temporary files.
enum ShelfItemFactory {
    /// Creates a ShelfItem from a real temp file.
    static func makeItem(
        named name: String = "testfile.txt",
        in directory: URL,
        contents: Data? = nil
    ) throws -> ShelfItem {
        let url = try TestFileHelper.createFile(named: name, in: directory, contents: contents)
        return ShelfItem(url: url)
    }

    /// Creates a ShelfItem from a real temp file with a specific size.
    static func makeItem(
        named name: String = "testfile.txt",
        in directory: URL,
        size: Int
    ) throws -> ShelfItem {
        let url = try TestFileHelper.createFile(named: name, in: directory, size: size)
        return ShelfItem(url: url)
    }

    /// Creates a ShelfItem backed by a directory.
    static func makeDirectoryItem(
        named name: String = "TestFolder",
        in directory: URL
    ) throws -> ShelfItem {
        let url = try TestFileHelper.createDirectory(named: name, in: directory)
        return ShelfItem(url: url)
    }

    /// Creates multiple ShelfItems with distinct names.
    static func makeItems(
        count: Int,
        in directory: URL,
        prefix: String = "file"
    ) throws -> [ShelfItem] {
        try (0..<count).map { i in
            try makeItem(named: "\(prefix)_\(i).txt", in: directory)
        }
    }
}
