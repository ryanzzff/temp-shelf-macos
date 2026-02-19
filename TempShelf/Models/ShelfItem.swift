import AppKit
import QuickLookThumbnailing
import UniformTypeIdentifiers

struct ShelfItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let url: URL
    let name: String
    let fileType: UTType?
    let dateAdded: Date
    let fileSize: Int64
    var icon: NSImage
    var thumbnail: NSImage?

    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var isDirectory: Bool {
        fileType == .folder || fileType == .directory
    }

    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.dateAdded = Date()

        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
        self.fileSize = Int64(resourceValues?.fileSize ?? 0)
        self.fileType = resourceValues?.contentType
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
        self.icon.size = NSSize(width: 64, height: 64)
        self.thumbnail = nil
    }

    static func == (lhs: ShelfItem, rhs: ShelfItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension ShelfItem {
    @MainActor
    func generateThumbnail(size: CGSize = CGSize(width: 128, height: 128)) async -> NSImage? {
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: NSScreen.main?.backingScaleFactor ?? 2.0,
            representationTypes: .thumbnail
        )

        do {
            let representation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            return representation.nsImage
        } catch {
            return nil
        }
    }
}
