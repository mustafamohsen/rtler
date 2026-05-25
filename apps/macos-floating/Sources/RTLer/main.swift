import AppKit
import RtlerFloatingCore

private final class FloatingButtonView: NSView {
    var onClick: (() -> Void)?
    var onDragEnd: (() -> Void)?

    private let label = NSTextField(labelWithString: "RTL")
    private var mouseDownScreenLocation: NSPoint?
    private var initialWindowOrigin: NSPoint?
    private var didDrag = false
    private let dragThreshold: CGFloat = 4

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = min(bounds.width, bounds.height) / 2
        layer?.backgroundColor = NSColor.systemBlue.cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.22
        layer?.shadowRadius = 8
        layer?.shadowOffset = NSSize(width: 0, height: -2)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 14)
        label.alignment = .center
        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override func layout() {
        super.layout()
        layer?.cornerRadius = min(bounds.width, bounds.height) / 2
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownScreenLocation = NSEvent.mouseLocation
        initialWindowOrigin = window?.frame.origin
        didDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let mouseDownScreenLocation, let initialWindowOrigin else { return }

        let currentLocation = NSEvent.mouseLocation
        let deltaX = currentLocation.x - mouseDownScreenLocation.x
        let deltaY = currentLocation.y - mouseDownScreenLocation.y

        if hypot(deltaX, deltaY) > dragThreshold {
            didDrag = true
        }

        window?.setFrameOrigin(NSPoint(x: initialWindowOrigin.x + deltaX, y: initialWindowOrigin.y + deltaY))
    }

    override func mouseUp(with event: NSEvent) {
        if didDrag {
            onDragEnd?()
        } else {
            onClick?()
        }
        mouseDownScreenLocation = nil
        initialWindowOrigin = nil
        didDrag = false
    }

    func showFeedback(title: String, color: NSColor, duration: TimeInterval = 0.55) {
        animateFeedbackTransition(title: title, color: color)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.animateFeedbackTransition(title: "RTL", color: .systemBlue)
        }
    }

    private func animateFeedbackTransition(title: String, color: NSColor) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            label.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            guard let self else { return }
            self.label.stringValue = title
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.label.animator().alphaValue = 1
            }
        }

        guard let layer else { return }
        let colorAnimation = CABasicAnimation(keyPath: "backgroundColor")
        colorAnimation.fromValue = layer.presentation()?.backgroundColor ?? layer.backgroundColor
        colorAnimation.toValue = color.cgColor
        colorAnimation.duration = 0.18
        colorAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(colorAnimation, forKey: "rtler.feedback.backgroundColor")
        layer.backgroundColor = color.cgColor
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let savedPanelOriginKey = "RTLer.panelOrigin"
    private static let defaultPanelOrigin = NSPoint(x: 80, y: 500)

    private var panel: NSPanel!
    private var buttonView: FloatingButtonView!
    private var statusItem: NSStatusItem!
    private let service = SelectionReplacementService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        createStatusMenu()
        createFloatingButton()
    }

    private func createFloatingButton() {
        let buttonSize = NSSize(width: 56, height: 56)
        let panelSize = NSSize(width: 80, height: 80)
        panel = NSPanel(
            contentRect: NSRect(origin: restoredPanelOrigin(panelSize: panelSize), size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear
        panel.isOpaque = false

        buttonView = FloatingButtonView(
            frame: NSRect(
                x: (panelSize.width - buttonSize.width) / 2,
                y: (panelSize.height - buttonSize.height) / 2,
                width: buttonSize.width,
                height: buttonSize.height
            )
        )
        buttonView.onClick = { [weak self] in
            self?.convertSelection()
        }
        buttonView.onDragEnd = { [weak self] in
            self?.savePanelOrigin()
        }

        panel.contentView = buttonView
        panel.orderFrontRegardless()
    }

    private func convertSelection() {
        NSLog("RTLER floating button clicked")
        do {
            let outcome = try service.replaceSelection()
            switch outcome {
            case .selectionReplaced:
                NSLog("RTLER replacement succeeded")
                buttonView.showFeedback(title: "✓", color: .systemGreen)
            case .clipboardTransformed:
                NSLog("RTLER clipboard transform succeeded")
                buttonView.showFeedback(title: "⧉", color: .systemTeal)
            }
        } catch ReplacementError.accessibilityPermissionRequired {
            NSLog("RTLER replacement failed: Accessibility permission required")
            promptForAccessibilityPermission()
            buttonView.showFeedback(title: "!", color: .systemOrange)
        } catch {
            NSLog("RTLER replacement failed: \(String(describing: error))")
            buttonView.showFeedback(title: "!", color: .systemRed)
        }
    }

    private func createStatusMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "RTL"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Floating Button", action: #selector(showFloatingButton), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Hide Floating Button", action: #selector(hideFloatingButton), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Reset Button Position", action: #selector(resetButtonPosition), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Open Accessibility Settings", action: #selector(openAccessibilitySettings), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit RTLer", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func showFloatingButton() {
        panel.orderFrontRegardless()
    }

    @objc private func hideFloatingButton() {
        panel.orderOut(nil)
    }

    @objc private func resetButtonPosition() {
        panel.setFrameOrigin(Self.defaultPanelOrigin)
        savePanelOrigin()
        panel.orderFrontRegardless()
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func savePanelOrigin() {
        let origin = panel.frame.origin
        UserDefaults.standard.set(["x": origin.x, "y": origin.y], forKey: Self.savedPanelOriginKey)
    }

    private func restoredPanelOrigin(panelSize: NSSize) -> NSPoint {
        guard let stored = UserDefaults.standard.dictionary(forKey: Self.savedPanelOriginKey),
              let x = stored["x"] as? CGFloat,
              let y = stored["y"] as? CGFloat else {
            return Self.defaultPanelOrigin
        }
        return clampedPanelOrigin(NSPoint(x: x, y: y), panelSize: panelSize)
    }

    private func clampedPanelOrigin(_ origin: NSPoint, panelSize: NSSize) -> NSPoint {
        let screenFrame = NSScreen.screens.first { $0.visibleFrame.contains(origin) }?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        return NSPoint(
            x: min(max(origin.x, screenFrame.minX), screenFrame.maxX - panelSize.width),
            y: min(max(origin.y, screenFrame.minY), screenFrame.maxY - panelSize.height)
        )
    }

    private func promptForAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        openAccessibilitySettings()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
