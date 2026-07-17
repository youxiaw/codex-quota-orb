import AppKit
import SwiftUI

final class OrbWindowController: NSObject, NSWindowDelegate {
    private let state: QuotaState
    private let onToggleDetail: (NSRect) -> Void
    private let onRefresh: () -> Void
    private let onQuit: () -> Void
    private let window: NSWindow

    init(
        state: QuotaState,
        onToggleDetail: @escaping (NSRect) -> Void,
        onRefresh: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.state = state
        self.onToggleDetail = onToggleDetail
        self.onRefresh = onRefresh
        self.onQuit = onQuit

        let size = NSSize(width: 92, height: 92)
        let origin = Self.savedOrigin(defaultSize: size)
        self.window = NSWindow(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        super.init()

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.delegate = self
        let hostingView = NSHostingView(
            rootView: OrbView(
                state: state,
                onToggle: { [weak self] in
                    guard let self else { return }
                    self.onToggleDetail(self.window.frame)
                },
                onRefresh: onRefresh,
                onQuit: onQuit
            )
        )
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.cornerRadius = size.width / 2
        hostingView.layer?.masksToBounds = true
        window.contentView = hostingView
    }

    func show() {
        window.makeKeyAndOrderFront(nil)
    }

    func windowDidMove(_ notification: Notification) {
        let origin = window.frame.origin
        UserDefaults.standard.set(origin.x, forKey: "orb.origin.x")
        UserDefaults.standard.set(origin.y, forKey: "orb.origin.y")
    }

    private static func savedOrigin(defaultSize: NSSize) -> NSPoint {
        if UserDefaults.standard.object(forKey: "orb.origin.x") != nil,
           UserDefaults.standard.object(forKey: "orb.origin.y") != nil {
            return NSPoint(
                x: UserDefaults.standard.double(forKey: "orb.origin.x"),
                y: UserDefaults.standard.double(forKey: "orb.origin.y")
            )
        }

        let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 80, y: 80, width: 1200, height: 800)
        return NSPoint(
            x: visible.maxX - defaultSize.width - 36,
            y: visible.maxY - defaultSize.height - 80
        )
    }
}
