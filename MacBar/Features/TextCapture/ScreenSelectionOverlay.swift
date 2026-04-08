import AppKit

final class ScreenSelectionOverlay {
    private var overlayWindows: [NSWindow] = []
    private var completion: ((NSRect) -> Void)?

    func start(completion: @escaping (NSRect) -> Void) {
        self.completion = completion

        for screen in NSScreen.screens {
            let window = SelectionWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.level = .init(Int(CGShieldingWindowLevel()) + 1)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.ignoresMouseEvents = false
            window.hasShadow = false

            let view = SelectionDragView(frame: screen.frame)
            view.onComplete = { [weak self] rect in
                let screenRect = NSRect(
                    x: screen.frame.origin.x + rect.origin.x,
                    y: screen.frame.origin.y + rect.origin.y,
                    width: rect.width,
                    height: rect.height
                )
                self?.finishSelection(screenRect: screenRect)
            }
            view.onCancel = { [weak self] in
                self?.cancel()
            }
            window.contentView = view
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(view)
            window.disableCursorRects()
            overlayWindows.append(window)
        }

        // Set crosshair AFTER all windows are up and rendered
        DispatchQueue.main.async {
            NSCursor.crosshair.set()
        }
    }

    private func finishSelection(screenRect: NSRect) {
        closeOverlays()
        completion?(screenRect)
    }

    private func cancel() {
        closeOverlays()
    }

    private func closeOverlays() {
        NSCursor.arrow.set()
        for window in overlayWindows {
            window.enableCursorRects()
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }
}

// MARK: - Window that can become key + forces crosshair

final class SelectionWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func becomeKey() {
        super.becomeKey()
        NSCursor.crosshair.set()
    }
}

// MARK: - Drag Selection View

final class SelectionDragView: NSView {
    var onComplete: ((NSRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentRect: NSRect?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        NSCursor.crosshair.set()
    }

    // Accept the very first click without needing to activate window first
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        NSCursor.crosshair.set()
        startPoint = convert(event.locationInWindow, from: nil)
        currentRect = nil
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)
        let x = min(start.x, current.x)
        let y = min(start.y, current.y)
        let w = abs(current.x - start.x)
        let h = abs(current.y - start.y)
        currentRect = NSRect(x: x, y: y, width: w, height: h)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let rect = currentRect, rect.width > 4, rect.height > 4 else {
            onCancel?()
            return
        }
        onComplete?(rect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.3).setFill()
        bounds.fill()

        guard let rect = currentRect else { return }

        // Clear selection area
        NSGraphicsContext.current?.compositingOperation = .clear
        rect.fill()

        // Blue selection fill + border
        NSGraphicsContext.current?.compositingOperation = .sourceOver
        NSColor.systemBlue.withAlphaComponent(0.15).setFill()
        rect.fill()

        NSColor.systemBlue.setStroke()
        let border = NSBezierPath(rect: rect)
        border.lineWidth = 2
        border.stroke()
    }
}
