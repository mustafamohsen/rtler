import AppKit
import RtlerFloatingCore

private final class FloatingButtonView: NSView {
    var onClick: (() -> Void)?
    var onDragEnd: (() -> Void)?

    private let backgroundLayer = CAGradientLayer()
    private let borderLayer = CAShapeLayer()
    private let innerHighlightLayer = CAShapeLayer()
    private let topLineLayer = CAShapeLayer()
    private let middleLineLayer = CAShapeLayer()
    private let bottomLineLayer = CAShapeLayer()
    private let directionLayer = CAShapeLayer()
    private let feedbackLabel = NSTextField(labelWithString: "")
    private var mouseDownScreenLocation: NSPoint?
    private var initialWindowOrigin: NSPoint?
    private var didDrag = false
    private let dragThreshold: CGFloat = 4
    private let idleTopColor = NSColor(red: 0.067, green: 0.094, blue: 0.145, alpha: 0.96)
    private let idleBottomColor = NSColor(red: 0.026, green: 0.039, blue: 0.078, alpha: 0.98)
    private let accentColor = NSColor(red: 0.49, green: 0.827, blue: 0.988, alpha: 1)

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
        layer?.masksToBounds = false
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.20
        layer?.shadowRadius = 10
        layer?.shadowOffset = NSSize(width: 0, height: -4)

        backgroundLayer.colors = [cgColor(idleTopColor), cgColor(idleBottomColor)]
        backgroundLayer.startPoint = CGPoint(x: 0.18, y: 0.08)
        backgroundLayer.endPoint = CGPoint(x: 0.86, y: 0.94)
        layer?.addSublayer(backgroundLayer)

        borderLayer.fillColor = NSColor.clear.cgColor
        borderLayer.strokeColor = NSColor.white.withAlphaComponent(0.14).cgColor
        borderLayer.lineWidth = 1
        layer?.addSublayer(borderLayer)

        innerHighlightLayer.fillColor = NSColor.clear.cgColor
        innerHighlightLayer.strokeColor = NSColor.white.withAlphaComponent(0.08).cgColor
        innerHighlightLayer.lineWidth = 1
        layer?.addSublayer(innerHighlightLayer)

        configureGlyphLine(topLineLayer, alpha: 0.92)
        configureGlyphLine(middleLineLayer, alpha: 0.70)
        configureGlyphLine(bottomLineLayer, alpha: 0.48)
        layer?.addSublayer(topLineLayer)
        layer?.addSublayer(middleLineLayer)
        layer?.addSublayer(bottomLineLayer)

        directionLayer.fillColor = NSColor.clear.cgColor
        directionLayer.strokeColor = cgColor(accentColor)
        directionLayer.lineWidth = 2.1
        directionLayer.lineCap = .round
        directionLayer.lineJoin = .round
        layer?.addSublayer(directionLayer)

        feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
        feedbackLabel.alphaValue = 0
        feedbackLabel.textColor = .white
        feedbackLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        feedbackLabel.alignment = .center
        addSubview(feedbackLabel)

        NSLayoutConstraint.activate([
            feedbackLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            feedbackLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -0.5)
        ])
    }

    override func layout() {
        super.layout()
        let buttonFrame = bounds.insetBy(dx: 1, dy: 1)
        let cornerRadius = min(buttonFrame.width, buttonFrame.height) * 0.30

        backgroundLayer.frame = buttonFrame
        backgroundLayer.cornerRadius = cornerRadius
        backgroundLayer.cornerCurve = .continuous

        let borderPath = CGPath(
            roundedRect: buttonFrame,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        borderLayer.path = borderPath
        innerHighlightLayer.path = CGPath(
            roundedRect: buttonFrame.insetBy(dx: 1.8, dy: 1.8),
            cornerWidth: max(cornerRadius - 1.8, 0),
            cornerHeight: max(cornerRadius - 1.8, 0),
            transform: nil
        )

        let glyphFrame = buttonFrame.insetBy(dx: 9.5, dy: 9.5)
        topLineLayer.path = linePath(from: glyphPoint(x: 32, y: 42, in: glyphFrame),
                                     to: glyphPoint(x: 93, y: 42, in: glyphFrame))
        middleLineLayer.path = linePath(from: glyphPoint(x: 52, y: 64, in: glyphFrame),
                                        to: glyphPoint(x: 93, y: 64, in: glyphFrame))
        bottomLineLayer.path = linePath(from: glyphPoint(x: 43, y: 86, in: glyphFrame),
                                        to: glyphPoint(x: 93, y: 86, in: glyphFrame))

        let directionPath = CGMutablePath()
        directionPath.move(to: glyphPoint(x: 39, y: 53, in: glyphFrame))
        directionPath.addLine(to: glyphPoint(x: 28, y: 64, in: glyphFrame))
        directionPath.addLine(to: glyphPoint(x: 39, y: 75, in: glyphFrame))
        directionLayer.path = directionPath
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownScreenLocation = NSEvent.mouseLocation
        initialWindowOrigin = window?.frame.origin
        didDrag = false
        animatePress(isPressed: true)
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let menu else { return }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
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
        animatePress(isPressed: false)
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
            self?.restoreIdleState()
        }
    }

    private func configureGlyphLine(_ layer: CAShapeLayer, alpha: CGFloat) {
        layer.fillColor = NSColor.clear.cgColor
        layer.strokeColor = NSColor.white.withAlphaComponent(alpha).cgColor
        layer.lineWidth = 2.6
        layer.lineCap = .round
    }

    private func linePath(from start: CGPoint, to end: CGPoint) -> CGPath {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }

    private func glyphPoint(x: CGFloat, y: CGFloat, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + (x / 128) * rect.width,
            y: rect.minY + ((128 - y) / 128) * rect.height
        )
    }

    private func animatePress(isPressed: Bool) {
        guard let layer else { return }
        let scale = isPressed ? 0.965 : 1
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            layer.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
        }
    }

    private func animateFeedbackTransition(title: String, color: NSColor) {
        feedbackLabel.stringValue = title
        feedbackLabel.textColor = .white
        setGlyphAlpha(0)
        setFeedbackAlpha(1)
        animateGradient(to: feedbackGradient(for: color))
        animateBorder(to: color.withAlphaComponent(0.34))
    }

    private func restoreIdleState() {
        setFeedbackAlpha(0)
        setGlyphAlpha(1)
        animateGradient(to: [cgColor(idleTopColor), cgColor(idleBottomColor)])
        animateBorder(to: NSColor.white.withAlphaComponent(0.14))
    }

    private func setGlyphAlpha(_ alpha: Float) {
        [topLineLayer, middleLineLayer, bottomLineLayer, directionLayer].forEach { glyphLayer in
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = glyphLayer.presentation()?.opacity ?? glyphLayer.opacity
            animation.toValue = alpha
            animation.duration = 0.16
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            glyphLayer.add(animation, forKey: "rtler.glyph.opacity")
            glyphLayer.opacity = alpha
        }
    }

    private func setFeedbackAlpha(_ alpha: CGFloat) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            feedbackLabel.animator().alphaValue = alpha
        }
    }

    private func animateGradient(to colors: [CGColor]) {
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = backgroundLayer.presentation()?.value(forKeyPath: "colors") ?? backgroundLayer.colors
        animation.toValue = colors
        animation.duration = 0.22
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        backgroundLayer.add(animation, forKey: "rtler.background.colors")
        backgroundLayer.colors = colors
    }

    private func animateBorder(to color: NSColor) {
        let cgColor = cgColor(color)
        let animation = CABasicAnimation(keyPath: "strokeColor")
        animation.fromValue = borderLayer.presentation()?.strokeColor ?? borderLayer.strokeColor
        animation.toValue = cgColor
        animation.duration = 0.22
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        borderLayer.add(animation, forKey: "rtler.border.color")
        borderLayer.strokeColor = cgColor
    }

    private func feedbackGradient(for color: NSColor) -> [CGColor] {
        let top = color.blended(withFraction: 0.42, of: idleTopColor) ?? color
        let bottom = color.blended(withFraction: 0.72, of: idleBottomColor) ?? color
        return [cgColor(top.withAlphaComponent(0.96)), cgColor(bottom.withAlphaComponent(0.98))]
    }

    private func cgColor(_ color: NSColor) -> CGColor {
        (color.usingColorSpace(.sRGB) ?? color).cgColor
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
        let buttonSize = NSSize(width: 44, height: 44)
        let panelSize = NSSize(width: 54, height: 54)
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
        panel.hasShadow = false

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
        buttonView.menu = createFloatingButtonContextMenu()

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
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let statusIcon = loadStatusIcon() {
            statusIcon.size = NSSize(width: 18, height: 18)
            statusIcon.isTemplate = true
            statusItem.button?.image = statusIcon
            statusItem.button?.imagePosition = .imageOnly
        } else {
            statusItem.button?.title = "RTL"
        }

        statusItem.menu = createStatusMenuItems(includeShow: true)
    }

    private func createFloatingButtonContextMenu() -> NSMenu {
        createStatusMenuItems(includeShow: false)
    }

    private func createStatusMenuItems(includeShow: Bool) -> NSMenu {
        let menu = NSMenu()
        if includeShow {
            menu.addItem(menuItem(title: "Show Floating Button", action: #selector(showFloatingButton)))
        }
        menu.addItem(menuItem(title: "Hide Floating Button", action: #selector(hideFloatingButton)))
        menu.addItem(menuItem(title: "Reset Button Position", action: #selector(resetButtonPosition)))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Open Accessibility Settings", action: #selector(openAccessibilitySettings)))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Quit RTLer", action: #selector(quit), keyEquivalent: "q"))
        return menu
    }

    private func menuItem(title: String, action: Selector, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func loadStatusIcon() -> NSImage? {
        let fileManager = FileManager.default
        let candidateURLs: [URL] = [
            Bundle.main.url(forResource: "MenuBarIconTemplate", withExtension: "png"),
            URL(fileURLWithPath: fileManager.currentDirectoryPath)
                .appendingPathComponent("Resources/MenuBarIconTemplate.png"),
            URL(fileURLWithPath: fileManager.currentDirectoryPath)
                .appendingPathComponent("apps/macos-floating/Resources/MenuBarIconTemplate.png")
        ].compactMap { $0 }

        for url in candidateURLs where fileManager.fileExists(atPath: url.path) {
            if let image = NSImage(contentsOf: url) {
                return image
            }
        }
        return nil
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
