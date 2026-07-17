import AppKit

struct PanelPlacement {
    let frame: NSRect
    let opensToRight: Bool
}

enum PanelPlacementCalculator {
    static func place(
        near anchor: NSRect,
        panelSize: NSSize,
        visibleFrame: NSRect,
        gap: CGFloat,
        margin: CGFloat
    ) -> PanelPlacement {
        let rightX = anchor.maxX + gap
        let leftX = anchor.minX - panelSize.width - gap
        let opensToRight = rightX + panelSize.width <= visibleFrame.maxX - margin
            || leftX < visibleFrame.minX + margin
        let preferredX = opensToRight ? rightX : leftX
        let preferredY = anchor.midY - panelSize.height / 2

        let x = min(max(preferredX, visibleFrame.minX + margin), visibleFrame.maxX - panelSize.width - margin)
        let y = min(max(preferredY, visibleFrame.minY + margin), visibleFrame.maxY - panelSize.height - margin)

        return PanelPlacement(
            frame: NSRect(origin: NSPoint(x: x, y: y), size: panelSize),
            opensToRight: opensToRight
        )
    }
}
