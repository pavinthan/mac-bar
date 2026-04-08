import AppKit

final class SelectionHighlight {
    private var window: NSWindow?

    func show(rect: NSRect) {
        let window = NSWindow(
            contentRect: rect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.08)
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false

        window.contentView?.wantsLayer = true
        window.contentView?.layer?.borderWidth = 2
        window.contentView?.layer?.borderColor = NSColor.systemBlue.withAlphaComponent(0.6).cgColor
        window.contentView?.layer?.cornerRadius = 2

        window.orderFrontRegardless()
        self.window = window
    }

    func dismiss() {
        window?.orderOut(nil)
        window = nil
    }
}
