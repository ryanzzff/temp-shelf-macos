import Foundation

/// Creates and cleans up temporary files and directories for testing.
enum TestFileHelper {
    private static let testDirectoryName = "TempShelfTests"

    /// Returns a unique temporary directory for a single test run.
    static func makeTestDirectory() throws -> URL {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent(testDirectoryName, isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    /// Creates a temporary file with the given name and optional data.
    @discardableResult
    static func createFile(
        named name: String,
        in directory: URL,
        contents: Data? = nil
    ) throws -> URL {
        let url = directory.appendingPathComponent(name)
        let data = contents ?? Data("test content".utf8)
        try data.write(to: url)
        return url
    }

    /// Creates a temporary file with a specific size in bytes.
    @discardableResult
    static func createFile(
        named name: String,
        in directory: URL,
        size: Int
    ) throws -> URL {
        let url = directory.appendingPathComponent(name)
        let data = Data(repeating: 0x41, count: size)
        try data.write(to: url)
        return url
    }

    /// Creates a subdirectory inside the given directory.
    @discardableResult
    static func createDirectory(
        named name: String,
        in directory: URL
    ) throws -> URL {
        let url = directory.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Removes the directory and all its contents.
    static func cleanup(directory: URL) {
        try? FileManager.default.removeItem(at: directory)
    }
}
