import AppKit
import SwiftUI

final class DetailPanelController {
    private let window: NSWindow

    init(state: QuotaState) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 390, height: 420),
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
            window.orderOut(nil)
            return
        }

        let target = NSPoint(x: anchor.minX - 410, y: anchor.maxY - 420)
        window.setFrameOrigin(target)
        window.makeKeyAndOrderFront(nil)
    }
}
