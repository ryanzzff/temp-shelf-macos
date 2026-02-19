# Temp Shelf for macOS - Research & Feature Plan

## Context

Building a macOS app that serves as a temporary file shelf / holding area for drag-and-drop workflows. The goal is to research the competitive landscape, identify features worth implementing, and choose the best tech stack for performance.

---

## 1. Existing App Landscape

### Tier 1: Market Leaders

| App | Price | Activation | Key Differentiator |
|-----|-------|-----------|-------------------|
| **Yoink** | $8.99 | Auto-appears at screen edge on drag start | Clipboard history, Handoff between devices, Shortcuts integration |
| **Dropover** | $3.99 | Shake cursor gesture / hotkey | Cloud sharing (iCloud, S3, Dropbox, GDrive), shelf color-coding, built-in actions (resize images, extract text) |
| **Dropzone 4** | Free core / $35 Pro | Menu bar panel | Extensible actions (FTP upload, cloud services), app launcher integration |

### Tier 2: Niche / Legacy

| App | Notes |
|-----|-------|
| **Dropshelf** | Screen-edge slide-out, cross-platform (also Windows) |
| **Gladys** | Apple ecosystem (Mac, iPhone, iPad, Watch), holds links/text/maps/contacts |
| **Unclutter** | Notes + clipboard + files in one pull-down panel |
| **ExtraDock** | Dock-integrated shelves, multiple monitors, unlimited shelves |
| **FilePane** | Quick file actions on drag (rename, compress, share) |

### Common Pain Points Across Existing Apps
- **Single shelf limitation** - most apps only show one shelf at a time
- **Poor multi-monitor support** - shelves don't follow across screens well
- **No context/project awareness** - shelves are generic, not tied to workflows
- **Limited file preview** - most show just icons, not rich previews
- **No auto-cleanup** - files pile up, manual cleanup required
- **No smart organization** - everything dumped in one flat list

---

## 2. Proposed Feature Set

### Phase 1: Core MVP
- **Floating shelf window** - always-on-top panel that appears on drag start (like Yoink) or via hotkey
- **Drag-in from anywhere** - accept files, folders, images, text, URLs from any app
- **Drag-out to anywhere** - drag items from shelf to Finder, apps, etc.
- **Copy vs Move** - hold modifier key (Option) to choose copy vs move semantics
- **Quick Look preview** - spacebar to preview files on the shelf (leveraging macOS Quick Look)
- **Auto-hide** - shelf slides away when not in use, reappears on drag start
- **Menu bar icon** - persistent access + settings
- **Multiple items** - stack multiple files, select all / individual drag-out

### Phase 2: Differentiators
- **Multiple named shelves** - create project-specific shelves (e.g., "Design Assets", "PR Review Files")
- **Auto-expire / TTL** - files auto-removed after configurable time (1hr, 1 day, 1 week)
- **Smart stacks** - auto-group by file type (images, documents, code)
- **File actions** - right-click menu: compress, share via AirDrop, copy path, reveal in Finder, rename
- **Multi-monitor aware** - shelf appears on the screen where the drag started
- **Keyboard navigation** - arrow keys to select, Enter to open, Delete to remove, Cmd+C to copy path
- **Drag counter badge** - show count of items on shelf in menu bar

### Phase 3: Power Features
- **Clipboard history integration** - catch clipboard items alongside dragged files
- **Shelf templates** - save shelf configurations for recurring workflows
- **Finder extension** - right-click "Send to Shelf" in Finder context menu
- **Shortcuts/Automation** - expose actions to macOS Shortcuts app
- **Handoff** - transfer shelf contents between Mac devices via iCloud
- **Image quick actions** - resize, convert format, strip metadata directly from shelf
- **Batch rename** - rename multiple files on shelf before moving to destination
- **Search** - fuzzy search across all shelves
- **Drag from browser** - intercept browser downloads to shelf

---

## 3. Tech Stack Decision

### Chosen: Swift + SwiftUI (with AppKit bridging)

| Aspect | Details |
|--------|---------|
| **Performance** | Native binary, ~0% CPU idle, ~15-30MB RAM, instant startup |
| **Drag & Drop** | AppKit NSDraggingDestination / NSDraggingSource + NSPasteboard for robust file drag-and-drop |
| **Floating Window** | NSPanel with `.floating` level, `.nonactivatingPanel` - exactly how Yoink/Dropover work |
| **UI** | SwiftUI declarative views with AppKit bridging for drag/drop and window management |
| **System Integration** | Full access: Accessibility APIs, Services menu, Finder extensions, Shortcuts, Quick Look |
| **App Size** | ~5-10MB |
| **Deployment Target** | macOS 14.0+ |

### Why Not Others
- **Pure AppKit** - too verbose for UI, SwiftUI is faster for views/animations
- **Tauri/Electron** - no deep macOS integration (Finder extension, NSPasteboard, Quick Look), heavier
- **Flutter** - poor macOS system integration, no NSPanel, limited pasteboard access

---

## 4. Architecture

```
TempShelf.app
├── App/                    # SwiftUI App lifecycle, AppDelegate, menu bar
├── Views/                  # SwiftUI views (shelf UI, settings, keyboard handling)
├── Panels/                 # AppKit NSPanel wrappers for floating windows
├── DragDrop/               # AppKit NSDraggingDestination/Source, drag-out views
├── Models/                 # ShelfItem, ShelfStore (ObservableObject state)
├── Services/               # DragMonitor, QuickLookCoordinator
└── Resources/              # Assets, entitlements
```

Key design decisions:
- **NSPanel** (not NSWindow) for the floating shelf - stays on top without stealing focus
- **AppKit NSDraggingSession** for drag-out - writes NSURL directly to pasteboard (Finder-compatible)
- **ShelfDropView** (NSVisualEffectView subclass) for drag-in - implements NSDraggingDestination
- **WindowDragView** for panel repositioning - only the header area moves the panel, not item rows
- **LSUIElement** app - menu bar only, no Dock icon

---

## 5. Verification Plan
- Build a minimal floating panel prototype that accepts file drops
- Verify drag-out works to Finder and other apps
- Test on multiple monitors
- Measure memory footprint and CPU at idle
- Test with 50+ files on shelf for performance
