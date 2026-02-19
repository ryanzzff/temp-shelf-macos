import SwiftUI

/// The main SwiftUI view displayed inside the floating panel.
struct ShelfContentView: View {
    @ObservedObject var shelfStore: ShelfStore
    let panelController: FloatingPanelController

    var body: some View {
        VStack(spacing: 0) {
            // Header - also serves as the window drag handle
            WindowDragArea {
                HStack {
                    Text("Shelf")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    if !shelfStore.items.isEmpty {
                        Text("\(shelfStore.items.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.quaternary))
                    }
                    Button {
                        panelController.hidePanel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }

            Divider()
                .padding(.horizontal, 8)

            // Content
            if shelfStore.items.isEmpty {
                emptyState
            } else {
                itemsList
            }
        }
        .frame(minWidth: 260, maxWidth: 320, minHeight: 200, maxHeight: 600)
        .background {
            KeyboardHandlingView(shelfStore: shelfStore)
                .frame(width: 0, height: 0)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("Drop files here")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Drag files from Finder or\nany app to the shelf")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private func urlsToDrag(for item: ShelfItem) -> [URL] {
        if shelfStore.selectedItemIDs.contains(item.id) {
            return shelfStore.selectedItems.map(\.url)
        }
        return [item.url]
    }

    private var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(shelfStore.items) { item in
                    DraggableFileView(
                        fileURLs: urlsToDrag(for: item),
                        dragImage: item.icon,
                        onDragCompleted: { operation in
                            Task { @MainActor in
                                // Remove dragged items from shelf after successful drag-out
                                let draggedURLs = urlsToDrag(for: item)
                                let itemsToRemove = shelfStore.items.filter { draggedURLs.contains($0.url) }
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    shelfStore.removeItems(itemsToRemove)
                                }
                            }
                        }
                    ) {
                        ShelfItemRow(
                            item: item,
                            isSelected: shelfStore.selectedItemIDs.contains(item.id),
                            shelfStore: shelfStore
                        )
                    }
                    .onTapGesture {
                        if NSEvent.modifierFlags.contains(.command) {
                            shelfStore.toggleSelection(item)
                        } else {
                            shelfStore.selectOnly(item)
                        }
                    }
                    .contextMenu {
                        Button("Open") {
                            NSWorkspace.shared.open(item.url)
                        }
                        Button("Reveal in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([item.url])
                        }
                        Divider()
                        Button("Copy Path") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(item.url.path, forType: .string)
                        }
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.writeObjects([item.url as NSURL])
                        }
                        Divider()
                        Button("Remove from Shelf", role: .destructive) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                shelfStore.removeItem(item)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
    }
}

/// SwiftUI wrapper that makes its content area draggable for window repositioning.
struct WindowDragArea<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .background(WindowDragNSView())
    }
}

/// Bridges an NSView that enables window dragging into SwiftUI.
private struct WindowDragNSView: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowDragView {
        let view = WindowDragView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        return view
    }

    func updateNSView(_ nsView: WindowDragView, context: Context) {}
}

struct ShelfItemRow: View {
    let item: ShelfItem
    let isSelected: Bool
    let shelfStore: ShelfStore

    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail or icon
            Group {
                if let thumbnail = item.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Image(nsImage: item.icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(item.fileSizeFormatted)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Quick action: remove
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    shelfStore.removeItem(item)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isSelected ? 1 : 0.001)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}
