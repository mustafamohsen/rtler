import AppKit
import Foundation

public enum ReplacementError: Error, Equatable {
    case accessibilityPermissionRequired
    case noSelectedText
    case transformFailed
}

public struct ClipboardSnapshot: Equatable {
    public let string: String?

    public init(string: String?) {
        self.string = string
    }
}

public protocol ClipboardStore {
    func snapshot() -> ClipboardSnapshot
    func restore(_ snapshot: ClipboardSnapshot)
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

public protocol FrontmostApplicationProvider {
    func frontmostApplication() -> NSRunningApplication?
}

public protocol ApplicationActivating {
    func activate(_ application: NSRunningApplication)
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

public struct WorkspaceFrontmostApplicationProvider: FrontmostApplicationProvider {
    public init() {}

    public func frontmostApplication() -> NSRunningApplication? {
        NSWorkspace.shared.frontmostApplication
    }
}

public struct RunningApplicationActivator: ApplicationActivating {
    public init() {}

    public func activate(_ application: NSRunningApplication) {
        application.activate(options: [.activateIgnoringOtherApps])
    }
}

public final class GeneralPasteboardStore: ClipboardStore {
    private let pasteboard = NSPasteboard.general

    public init() {}

    public func snapshot() -> ClipboardSnapshot {
        ClipboardSnapshot(string: pasteboard.string(forType: .string))
    }

    public func restore(_ snapshot: ClipboardSnapshot) {
        pasteboard.clearContents()
        if let string = snapshot.string {
            pasteboard.setString(string, forType: .string)
        }
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
    private let frontmostApplicationProvider: FrontmostApplicationProvider
    private let applicationActivator: ApplicationActivating
    private let pasteRestoreDelay: TimeInterval
    private let sleep: (TimeInterval) -> Void

    public init(
        clipboard: ClipboardStore = GeneralPasteboardStore(),
        keyboard: KeyboardEventSender = SystemKeyboardEventSender(),
        transformer: TextTransformer = RtlerTextTransformer(),
        permissions: PermissionChecking = AccessibilityPermissionChecker(),
        frontmostApplicationProvider: FrontmostApplicationProvider = WorkspaceFrontmostApplicationProvider(),
        applicationActivator: ApplicationActivating = RunningApplicationActivator(),
        pasteRestoreDelay: TimeInterval = SelectionReplacementService.defaultPasteRestoreDelay(),
        sleep: @escaping (TimeInterval) -> Void = { Thread.sleep(forTimeInterval: $0) }
    ) {
        self.clipboard = clipboard
        self.keyboard = keyboard
        self.transformer = transformer
        self.permissions = permissions
        self.frontmostApplicationProvider = frontmostApplicationProvider
        self.applicationActivator = applicationActivator
        self.pasteRestoreDelay = pasteRestoreDelay
        self.sleep = sleep
    }

    public func replaceSelection() throws {
        guard permissions.canControlComputer() else {
            throw ReplacementError.accessibilityPermissionRequired
        }

        NSLog("RTLER service: checking frontmost app")
        let sourceApplication = frontmostApplicationProvider.frontmostApplication()
        NSLog("RTLER service: source app = \(sourceApplication?.localizedName ?? "unknown")")

        NSLog("RTLER service: snapshotting plain-text clipboard")
        let originalClipboard = clipboard.snapshot()

        let preCopyChangeCount = clipboard.changeCount()
        NSLog("RTLER service: sending copy")
        keyboard.copy()
        waitForPasteboardChange(after: preCopyChangeCount, timeout: 0.50)

        guard let selectedText = clipboard.string(), !selectedText.isEmpty else {
            NSLog("RTLER service: no selected text found")
            clipboard.restore(originalClipboard)
            throw ReplacementError.noSelectedText
        }
        NSLog("RTLER service: copied \(selectedText.count) characters")

        guard let transformed = transformer.transform(selectedText) else {
            NSLog("RTLER service: transform failed")
            clipboard.restore(originalClipboard)
            throw ReplacementError.transformFailed
        }
        NSLog("RTLER service: transformed text to \(transformed.count) characters")

        clipboard.setString(transformed)
        if let sourceApplication {
            NSLog("RTLER service: reactivating source app")
            applicationActivator.activate(sourceApplication)
            sleep(0.05)
        }
        NSLog("RTLER service: sending paste")
        keyboard.paste()
        NSLog("RTLER service: waiting \(pasteRestoreDelay)s before restoring clipboard")
        sleep(pasteRestoreDelay)
        NSLog("RTLER service: restoring clipboard")
        clipboard.restore(originalClipboard)
    }

    public static func defaultPasteRestoreDelay() -> TimeInterval {
        guard let value = ProcessInfo.processInfo.environment["RTLER_PASTE_RESTORE_DELAY"],
              let delay = TimeInterval(value),
              delay >= 0 else {
            return 2.0
        }
        return delay
    }

    private func waitForPasteboardChange(after initialChangeCount: Int, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if clipboard.changeCount() != initialChangeCount {
                return
            }
            sleep(0.02)
        } while Date() < deadline
    }
}
