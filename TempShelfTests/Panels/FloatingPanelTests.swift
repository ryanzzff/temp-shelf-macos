import XCTest
import AppKit
@testable import TempShelf

final class FloatingPanelTests: XCTestCase {
    private var panel: FloatingPanel!

    override func setUp() async throws {
        try await super.setUp()
        panel = await MainActor.run {
            FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 300, height: 400))
        }
    }

    override func tearDown() async throws {
        await MainActor.run { panel = nil }
        try await super.tearDown()
    }

    // MARK: - Key / Main

    @MainActor
    func testCanBecomeKey() {
        XCTAssertTrue(panel.canBecomeKey)
    }

    @MainActor
    func testCannotBecomeMain() {
        XCTAssertFalse(panel.canBecomeMain)
    }

    // MARK: - Floating behavior

    @MainActor
    func testLevelIsFloating() {
        XCTAssertEqual(panel.level, .floating)
    }

    @MainActor
    func testIsFloatingPanel() {
        XCTAssertTrue(panel.isFloatingPanel)
    }

    @MainActor
    func testDoesNotHideOnDeactivate() {
        XCTAssertFalse(panel.hidesOnDeactivate)
    }

    // MARK: - Visual style

    @MainActor
    func testTitleVisibilityIsHidden() {
        XCTAssertEqual(panel.titleVisibility, .hidden)
    }

    @MainActor
    func testTitlebarIsTransparent() {
        XCTAssertTrue(panel.titlebarAppearsTransparent)
    }

    @MainActor
    func testIsNotMovableByWindowBackground() {
        XCTAssertFalse(panel.isMovableByWindowBackground)
    }

    @MainActor
    func testBackgroundIsClear() {
        XCTAssertEqual(panel.backgroundColor, .clear)
    }

    @MainActor
    func testIsNotOpaque() {
        XCTAssertFalse(panel.isOpaque)
    }

    // MARK: - Collection behavior

    @MainActor
    func testCollectionBehaviorContainsCanJoinAllSpaces() {
        XCTAssertTrue(panel.collectionBehavior.contains(.canJoinAllSpaces))
    }

    @MainActor
    func testCollectionBehaviorContainsFullScreenAuxiliary() {
        XCTAssertTrue(panel.collectionBehavior.contains(.fullScreenAuxiliary))
    }

    // MARK: - Animation

    @MainActor
    func testAnimationBehaviorIsUtilityWindow() {
        XCTAssertEqual(panel.animationBehavior, .utilityWindow)
    }

    // MARK: - Style mask

    @MainActor
    func testStyleMaskContainsNonActivatingPanel() {
        XCTAssertTrue(panel.styleMask.contains(.nonactivatingPanel))
    }
}
