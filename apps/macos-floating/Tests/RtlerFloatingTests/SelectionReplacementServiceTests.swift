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
            sleep: { _ in }
        )

        try service.replaceSelection()

        XCTAssertEqual(keyboard.events, ["copy", "paste"])
        XCTAssertEqual(clipboard.pastedText, "ﻡﻼﺳ")
        XCTAssertEqual(clipboard.currentText, "original")
    }

    func testRestoresClipboardWhenNoTextIsSelected() throws {
        let clipboard = FakeClipboard(selectedTextAfterCopy: nil, originalText: "original")
        let keyboard = FakeKeyboard()
        let service = SelectionReplacementService(
            clipboard: clipboard,
            keyboard: keyboard,
            transformer: FakeTransformer(output: "unused"),
            permissions: FakePermissions(allowed: true),
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
    private let originalItem = NSPasteboardItem()
    var currentText: String?
    var pastedText: String?

    init(selectedTextAfterCopy: String?, originalText: String) {
        self.selectedTextAfterCopy = selectedTextAfterCopy
        self.currentText = originalText
        originalItem.setString(originalText, forType: .string)
    }

    func snapshot() -> [NSPasteboardItem] {
        [originalItem]
    }

    func restore(_ snapshot: [NSPasteboardItem]) {
        currentText = snapshot.first?.string(forType: .string)
    }

    func string() -> String? {
        selectedTextAfterCopy
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
