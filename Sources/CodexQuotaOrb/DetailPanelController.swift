import AppKit
import QuartzCore
import SwiftUI

final class DetailPanelController {
    private static let size = NSSize(width: 472, height: 536)
    private static let gap: CGFloat = 14
    private static let margin: CGFloat = 12
    private let window: NSWindow
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?

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
        installOutsideClickMonitors()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            window.animator().setFrame(placement.frame, display: true)
        }
    }

    private func hide() {
        removeOutsideClickMonitors()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: {
            self.window.orderOut(nil)
            self.window.alphaValue = 1
        }
    }

    private func hideIfVisible() {
        guard window.isVisible else {
            return
        }
        hide()
    }

    private func installOutsideClickMonitors() {
        removeOutsideClickMonitors()

        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else {
                return event
            }
            if event.window !== self.window {
                self.hideIfVisible()
            }
            return event
        }

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.hideIfVisible()
            }
        }
    }

    private func removeOutsideClickMonitors() {
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }
    }

    private func panelPlacement(near anchor: NSRect) -> PanelPlacement {
        let visible = screen(containing: anchor)?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1200, height: 800)

        return PanelPlacementCalculator.place(
            near: anchor,
            panelSize: Self.size,
            visibleFrame: visible,
            gap: Self.gap,
            margin: Self.margin
        )
    }

    private func screen(containing rect: NSRect) -> NSScreen? {
        let center = NSPoint(x: rect.midX, y: rect.midY)
        return NSScreen.screens.first { screen in
            screen.frame.contains(center)
        }
    }
}
