//
// OfficialEmulatorToolbarRepairService.swift
// MacDroid
//
// Keeps Google's official Android Emulator toolbar visible, but makes its most
// useful buttons reliable. The service places tiny transparent macOS panels over
// the toolbar buttons and routes those clicks through MacDroid's ADB controls.

import AppKit

@MainActor
final class OfficialEmulatorToolbarRepairService {
    private struct ToolbarButtonTarget: Identifiable {
        let action: EmulatorControlAction
        let centerYFromTop: CGFloat

        var id: EmulatorControlAction { action }
    }

    private let logService: LogService
    private var timer: Timer?
    private var overlayPanels: [EmulatorControlAction: ToolbarClickPanel] = [:]
    private var clickHandler: ((EmulatorControlAction) -> Void)?
    private var hasLoggedReady = false

    private let targets: [ToolbarButtonTarget] = [
        ToolbarButtonTarget(action: .power, centerYFromTop: 48),
        ToolbarButtonTarget(action: .volumeUp, centerYFromTop: 92),
        ToolbarButtonTarget(action: .volumeDown, centerYFromTop: 136),
        ToolbarButtonTarget(action: .screenshot, centerYFromTop: 180),
        ToolbarButtonTarget(action: .rotateLeft, centerYFromTop: 268),
        ToolbarButtonTarget(action: .rotateRight, centerYFromTop: 312),
        ToolbarButtonTarget(action: .back, centerYFromTop: 356),
        ToolbarButtonTarget(action: .home, centerYFromTop: 400),
        ToolbarButtonTarget(action: .recents, centerYFromTop: 444)
    ]

    init(logService: LogService) {
        self.logService = logService
    }

    func start(clickHandler: @escaping (EmulatorControlAction) -> Void) {
        self.clickHandler = clickHandler

        guard timer == nil else {
            refreshOverlays()
            return
        }

        refreshOverlays()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshOverlays()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        hasLoggedReady = false
        closeOverlayPanels()
    }

    private func refreshOverlays() {
        guard let toolbarRect = officialToolbarRect() else {
            closeOverlayPanels()
            return
        }

        for target in targets {
            let buttonRect = overlayRect(for: target, in: toolbarRect)
            let panel = overlayPanels[target.action] ?? makePanel(for: target.action)
            panel.setFrame(buttonRect, display: true)
            panel.orderFrontRegardless()
            overlayPanels[target.action] = panel
        }

        if !hasLoggedReady {
            hasLoggedReady = true
            logService.log("Official Google Emulator toolbar repair is active. Toolbar clicks will be routed through ADB.", level: .success)
        }
    }

    private func makePanel(for action: EmulatorControlAction) -> ToolbarClickPanel {
        let panel = ToolbarClickPanel(action: action) { [weak self] selectedAction in
            self?.logService.log("Official toolbar \(selectedAction.title) click captured by MacDroid.", level: .info)
            self?.clickHandler?(selectedAction)
        }

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hidesOnDeactivate = false
        return panel
    }

    private func closeOverlayPanels() {
        overlayPanels.values.forEach { $0.close() }
        overlayPanels.removeAll()
    }

    private func overlayRect(for target: ToolbarButtonTarget, in toolbarRect: NSRect) -> NSRect {
        let buttonSize = NSSize(width: 42, height: 40)
        let centerX = toolbarRect.midX
        let centerY = toolbarRect.maxY - target.centerYFromTop

        return NSRect(
            x: centerX - buttonSize.width / 2,
            y: centerY - buttonSize.height / 2,
            width: buttonSize.width,
            height: buttonSize.height
        )
    }

    private func officialToolbarRect() -> NSRect? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        let toolbarWindow = windowInfo.first { info in
            guard let ownerName = info[kCGWindowOwnerName as String] as? String,
                  ownerName == "qemu-system-aarch64",
                  let bounds = info[kCGWindowBounds as String] as? [String: Any],
                  let width = bounds["Width"] as? CGFloat,
                  let height = bounds["Height"] as? CGFloat else {
                return false
            }

            // Google's toolbar is a tall, narrow companion window. The emulator
            // display window is much wider, so this keeps the detection simple.
            return width >= 40 && width <= 120 && height >= 300
        }

        guard let bounds = toolbarWindow?[kCGWindowBounds as String] as? [String: Any],
              let x = bounds["X"] as? CGFloat,
              let y = bounds["Y"] as? CGFloat,
              let width = bounds["Width"] as? CGFloat,
              let height = bounds["Height"] as? CGFloat else {
            return nil
        }

        return convertTopLeftScreenRectToAppKitRect(
            CGRect(x: x, y: y, width: width, height: height)
        )
    }

    private func convertTopLeftScreenRectToAppKitRect(_ rect: CGRect) -> NSRect {
        let screenUnion = NSScreen.screens.reduce(CGRect.null) { partialResult, screen in
            partialResult.union(screen.frame)
        }

        return NSRect(
            x: rect.minX,
            y: screenUnion.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}

private final class ToolbarClickPanel: NSPanel {
    init(action: EmulatorControlAction, clickHandler: @escaping (EmulatorControlAction) -> Void) {
        let contentRect = NSRect(x: 0, y: 0, width: 42, height: 40)
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        contentView = ToolbarClickButton(action: action, clickHandler: clickHandler)
    }
}

private final class ToolbarClickButton: NSButton {
    private let emulatorAction: EmulatorControlAction
    private let clickHandler: (EmulatorControlAction) -> Void

    init(action: EmulatorControlAction, clickHandler: @escaping (EmulatorControlAction) -> Void) {
        self.emulatorAction = action
        self.clickHandler = clickHandler
        super.init(frame: .zero)
        title = ""
        isBordered = false
        bezelStyle = .regularSquare
        target = self
        self.action = #selector(runToolbarAction)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    @objc private func runToolbarAction() {
        clickHandler(emulatorAction)
    }
}
