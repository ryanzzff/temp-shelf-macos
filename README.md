# TempShelf for macOS

A lightweight macOS utility that acts as a temporary file shelf for drag-and-drop workflows. Drop files onto the floating shelf from any app, then drag them out to their destination. Think of it as a clipboard for files.

## Features

- **Floating shelf panel** - always-on-top, non-activating window that doesn't steal focus
- **Drag in from anywhere** - drop files, folders, images, and URLs from any app
- **Drag out to anywhere** - drag items from the shelf to Finder or any app
- **Auto-show on drag** - shelf appears automatically when you start dragging
- **Quick Look** - press Space to preview files on the shelf
- **Keyboard navigation** - arrow keys, Enter to open, Delete to remove, Cmd+A, Cmd+C
- **Right-click actions** - Open, Reveal in Finder, Copy Path, Remove
- **Menu bar icon** - access the shelf and settings from the menu bar
- **Hotkey** - Cmd+Shift+D to toggle the shelf

## Requirements

- macOS 14.0+
- Xcode 16+

## Building

```bash
xcodebuild -project TempShelf.xcodeproj -scheme TempShelf -configuration Debug build
```

Or open `TempShelf.xcodeproj` in Xcode and press Cmd+R.

## Tech Stack

Swift + SwiftUI with AppKit bridging. Native NSPanel for the floating window, AppKit NSDraggingSession for reliable file drag-and-drop that works with Finder.

## Project Structure

```
TempShelf/
├── App/          # App lifecycle, AppDelegate, menu bar integration
├── Views/        # SwiftUI views (shelf content, settings, keyboard handling)
├── Panels/       # FloatingPanel (NSPanel subclass) and controller
├── DragDrop/     # Drag-in (NSDraggingDestination) and drag-out (NSDraggingSource)
├── Models/       # ShelfItem model, ShelfStore state management
├── Services/     # Drag monitor, Quick Look coordinator
└── Resources/    # Assets, entitlements
```

## Docs

- [Feature Plan & Research](docs/PLAN.md) - competitive landscape, feature roadmap (Phase 1-3), tech stack analysis, and architecture decisions

## License

TBD
