import AppKit
import QuartzCore
import SwiftUI

final class DetailPanelController {
    private static let size = NSSize(width: 472, height: 536)
    private static let gap: CGFloat = 14
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
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let hostingView = NSHostingView(rootView: DetailPanelView(state: state))
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        window.contentView = hostingView
    }

    func toggle(near anchor: NSRect) {
        if window.isVisible {
            hide()
            return
        }

        show(near: anchor)
    }

    private func show(near anchor: NSRect) {
        let placement = panelPlacement(near: anchor)
        let startFrame = placement.frame.offsetBy(dx: placement.opensToRight ? -8 : 8, dy: -4)

        window.alphaValue = 0
        window.setFrame(startFrame, display: false)
        window.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            window.animator().setFrame(placement.frame, display: true)
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

    private func panelPlacement(near anchor: NSRect) -> (frame: NSRect, opensToRight: Bool) {
        let visible = screen(containing: anchor)?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1200, height: 800)

        let rightX = anchor.maxX + Self.gap
        let leftX = anchor.minX - Self.size.width - Self.gap
        let opensToRight = rightX + Self.size.width <= visible.maxX - 12 || leftX < visible.minX + 12
        let preferredX = opensToRight ? rightX : leftX
        let preferredY = anchor.midY - Self.size.height / 2

        let x = min(max(preferredX, visible.minX + 12), visible.maxX - Self.size.width - 12)
        let y = min(max(preferredY, visible.minY + 12), visible.maxY - Self.size.height - 12)
        return (NSRect(origin: NSPoint(x: x, y: y), size: Self.size), opensToRight)
    }

    private func screen(containing rect: NSRect) -> NSScreen? {
        let center = NSPoint(x: rect.midX, y: rect.midY)
        return NSScreen.screens.first { screen in
            screen.frame.contains(center)
        }
    }
}
