import AppKit
import RtlerFloatingCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private let service = SelectionReplacementService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        createFloatingButton()
    }

    private func createFloatingButton() {
        let size = NSSize(width: 56, height: 56)
        panel = NSPanel(
            contentRect: NSRect(origin: NSPoint(x: 80, y: 500), size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false

        let button = NSButton(frame: NSRect(origin: .zero, size: size))
        button.title = "RTL"
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 28
        button.layer?.backgroundColor = NSColor.systemBlue.cgColor
        button.contentTintColor = .white
        button.target = self
        button.action = #selector(convertSelection)

        panel.contentView = button
        panel.orderFrontRegardless()
    }

    @objc private func convertSelection() {
        NSLog("RTLER floating button clicked")
        do {
            try service.replaceSelection()
            NSLog("RTLER replacement succeeded")
            flash(color: .systemGreen)
        } catch ReplacementError.accessibilityPermissionRequired {
            NSLog("RTLER replacement failed: Accessibility permission required")
            promptForAccessibilityPermission()
            flash(color: .systemOrange)
        } catch {
            NSLog("RTLER replacement failed: \(String(describing: error))")
            flash(color: .systemRed)
        }
    }

    private func flash(color: NSColor) {
        guard let button = panel.contentView as? NSButton else { return }
        button.layer?.backgroundColor = color.cgColor
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            button.layer?.backgroundColor = NSColor.systemBlue.cgColor
        }
    }

    private func promptForAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
