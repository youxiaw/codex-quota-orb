import AppKit
import QuartzCore
import SwiftUI

final class DetailPanelController {
    private static let size = NSSize(width: 414, height: 438)
    private let window: NSWindow

    init(state: QuotaState) {
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = NSHostingView(rootView: DetailPanelView(state: state))
    }

    func toggle(near anchor: NSRect) {
        if window.isVisible {
            hide()
            return
        }

        show(near: anchor)
    }

    private func show(near anchor: NSRect) {
        let finalFrame = constrainedFrame(near: anchor)
        let startFrame = finalFrame.offsetBy(dx: 10, dy: -10)

        window.alphaValue = 0
        window.setFrame(startFrame, display: false)
        window.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            window.animator().setFrame(finalFrame, display: true)
        }
    }

    private func hide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: {
            self.window.orderOut(nil)
            self.window.alphaValue = 1
        }
    }

    private func constrainedFrame(near anchor: NSRect) -> NSRect {
        let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let preferred = NSPoint(
            x: anchor.minX - Self.size.width - 18,
            y: anchor.maxY - Self.size.height + 8
        )
        let x = min(max(preferred.x, visible.minX + 16), visible.maxX - Self.size.width - 16)
        let y = min(max(preferred.y, visible.minY + 16), visible.maxY - Self.size.height - 16)
        return NSRect(origin: NSPoint(x: x, y: y), size: Self.size)
    }
}
