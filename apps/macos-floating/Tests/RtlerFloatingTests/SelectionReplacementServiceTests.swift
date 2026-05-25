import AppKit
import XCTest
@testable import RtlerFloatingCore

final class SelectionReplacementServiceTests: XCTestCase {
    func testReplacesSelectedTextAndRestoresClipboard() throws {
        let clipboard = FakeClipboard(selectedTextAfterCopy: "سلام", originalText: "original")
        let keyboard = FakeKeyboard()
        let service = SelectionReplacementService(
            clipboard: clipboard,
            keyboard: keyboard,
            transformer: FakeTransformer(output: "ﻡﻼﺳ"),
            permissions: FakePermissions(allowed: true),
            frontmostApplicationProvider: FakeFrontmostApplicationProvider(),
            applicationActivator: FakeApplicationActivator(),
            pasteRestoreDelay: 0,
            sleep: { _ in }
        )

        let outcome = try service.replaceSelection()

        XCTAssertEqual(outcome, .selectionReplaced)
        XCTAssertEqual(keyboard.events, ["copy", "paste"])
        XCTAssertEqual(clipboard.pastedText, "ﻡﻼﺳ")
        XCTAssertEqual(clipboard.currentText, "original")
    }

    func testTransformsArabicClipboardWhenNoTextIsSelected() throws {
        let clipboard = FakeClipboard(selectedTextAfterCopy: nil, originalText: "سلام")
        let keyboard = FakeKeyboard()
        let service = SelectionReplacementService(
            clipboard: clipboard,
            keyboard: keyboard,
            transformer: FakeTransformer(output: "ﻡﻼﺳ"),
            permissions: FakePermissions(allowed: true),
            frontmostApplicationProvider: FakeFrontmostApplicationProvider(),
            applicationActivator: FakeApplicationActivator(),
            pasteRestoreDelay: 0,
            sleep: { _ in }
        )

        let outcome = try service.replaceSelection()

        XCTAssertEqual(outcome, .clipboardTransformed)
        XCTAssertEqual(keyboard.events, ["copy"])
        XCTAssertEqual(clipboard.pastedText, "ﻡﻼﺳ")
        XCTAssertEqual(clipboard.currentText, "ﻡﻼﺳ")
    }

    func testRestoresClipboardWhenNoTextIsSelectedAndClipboardIsNotArabic() throws {
        let clipboard = FakeClipboard(selectedTextAfterCopy: nil, originalText: "original")
        let keyboard = FakeKeyboard()
        let service = SelectionReplacementService(
            clipboard: clipboard,
            keyboard: keyboard,
            transformer: FakeTransformer(output: "unused"),
            permissions: FakePermissions(allowed: true),
            frontmostApplicationProvider: FakeFrontmostApplicationProvider(),
            applicationActivator: FakeApplicationActivator(),
            pasteRestoreDelay: 0,
            sleep: { _ in }
        )

        XCTAssertThrowsError(try service.replaceSelection()) { error in
            XCTAssertEqual(error as? ReplacementError, .noSelectedText)
        }
        XCTAssertEqual(keyboard.events, ["copy"])
        XCTAssertEqual(clipboard.currentText, "original")
    }

    func testDoesNotMutateClipboardWithoutAccessibilityPermission() throws {
        let clipboard = FakeClipboard(selectedTextAfterCopy: "سلام", originalText: "original")
        let keyboard = FakeKeyboard()
        let service = SelectionReplacementService(
            clipboard: clipboard,
            keyboard: keyboard,
            transformer: FakeTransformer(output: "ﻡﻼﺳ"),
            permissions: FakePermissions(allowed: false),
            frontmostApplicationProvider: FakeFrontmostApplicationProvider(),
            applicationActivator: FakeApplicationActivator(),
            pasteRestoreDelay: 0,
            sleep: { _ in }
        )

        XCTAssertThrowsError(try service.replaceSelection()) { error in
            XCTAssertEqual(error as? ReplacementError, .accessibilityPermissionRequired)
        }
        XCTAssertEqual(keyboard.events, [])
        XCTAssertEqual(clipboard.currentText, "original")
    }
}

private final class FakeClipboard: ClipboardStore {
    private let selectedTextAfterCopy: String?
    var currentText: String?
    var pastedText: String?

    init(selectedTextAfterCopy: String?, originalText: String) {
        self.selectedTextAfterCopy = selectedTextAfterCopy
        self.currentText = originalText
    }

    func snapshot() -> ClipboardSnapshot {
        ClipboardSnapshot(string: currentText)
    }

    func restore(_ snapshot: ClipboardSnapshot) {
        currentText = snapshot.string
    }

    func string() -> String? {
        selectedTextAfterCopy ?? currentText
    }

    func setString(_ string: String) {
        pastedText = string
        currentText = string
    }

    func changeCount() -> Int {
        0
    }
}

private final class FakeKeyboard: KeyboardEventSender {
    var events: [String] = []

    func copy() {
        events.append("copy")
    }

    func paste() {
        events.append("paste")
    }
}

private struct FakeTransformer: TextTransformer {
    let output: String?

    func transform(_ input: String) -> String? {
        output
    }
}

private struct FakePermissions: PermissionChecking {
    let allowed: Bool

    func canControlComputer() -> Bool {
        allowed
    }
}

private struct FakeFrontmostApplicationProvider: FrontmostApplicationProvider {
    func frontmostApplication() -> NSRunningApplication? {
        nil
    }
}

private struct FakeApplicationActivator: ApplicationActivating {
    func activate(_ application: NSRunningApplication) {}
}
