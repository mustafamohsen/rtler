import AppKit
import Foundation

public enum ReplacementError: Error, Equatable {
    case accessibilityPermissionRequired
    case noSelectedText
    case transformFailed
}

public protocol ClipboardStore {
    func snapshot() -> [NSPasteboardItem]
    func restore(_ snapshot: [NSPasteboardItem])
    func string() -> String?
    func setString(_ string: String)
    func changeCount() -> Int
}

public protocol KeyboardEventSender {
    func copy()
    func paste()
}

public protocol TextTransformer {
    func transform(_ input: String) -> String?
}

public protocol PermissionChecking {
    func canControlComputer() -> Bool
}

public struct RtlerTextTransformer: TextTransformer {
    public init() {}

    public func transform(_ input: String) -> String? {
        RtlerBridge.transform(input)
    }
}

public struct AccessibilityPermissionChecker: PermissionChecking {
    public init() {}

    public func canControlComputer() -> Bool {
        AXIsProcessTrusted()
    }
}

public final class GeneralPasteboardStore: ClipboardStore {
    private let pasteboard = NSPasteboard.general

    public init() {}

    public func snapshot() -> [NSPasteboardItem] {
        pasteboard.pasteboardItems?.compactMap { $0.copy() as? NSPasteboardItem } ?? []
    }

    public func restore(_ snapshot: [NSPasteboardItem]) {
        pasteboard.clearContents()
        pasteboard.writeObjects(snapshot)
    }

    public func string() -> String? {
        pasteboard.string(forType: .string)
    }

    public func setString(_ string: String) {
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    public func changeCount() -> Int {
        pasteboard.changeCount
    }
}

public struct SystemKeyboardEventSender: KeyboardEventSender {
    public init() {}

    public func copy() {
        sendCommandKey(keyCode: 8) // C
    }

    public func paste() {
        sendCommandKey(keyCode: 9) // V
    }

    private func sendCommandKey(keyCode: CGKeyCode) {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

public final class SelectionReplacementService {
    private let clipboard: ClipboardStore
    private let keyboard: KeyboardEventSender
    private let transformer: TextTransformer
    private let permissions: PermissionChecking
    private let sleep: (TimeInterval) -> Void

    public init(
        clipboard: ClipboardStore = GeneralPasteboardStore(),
        keyboard: KeyboardEventSender = SystemKeyboardEventSender(),
        transformer: TextTransformer = RtlerTextTransformer(),
        permissions: PermissionChecking = AccessibilityPermissionChecker(),
        sleep: @escaping (TimeInterval) -> Void = { Thread.sleep(forTimeInterval: $0) }
    ) {
        self.clipboard = clipboard
        self.keyboard = keyboard
        self.transformer = transformer
        self.permissions = permissions
        self.sleep = sleep
    }

    public func replaceSelection() throws {
        guard permissions.canControlComputer() else {
            throw ReplacementError.accessibilityPermissionRequired
        }

        let originalClipboard = clipboard.snapshot()
        keyboard.copy()
        sleep(0.12)

        guard let selectedText = clipboard.string(), !selectedText.isEmpty else {
            clipboard.restore(originalClipboard)
            throw ReplacementError.noSelectedText
        }

        guard let transformed = transformer.transform(selectedText) else {
            clipboard.restore(originalClipboard)
            throw ReplacementError.transformFailed
        }

        clipboard.setString(transformed)
        keyboard.paste()
        sleep(0.20)
        clipboard.restore(originalClipboard)
    }
}
