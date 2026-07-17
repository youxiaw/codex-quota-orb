import AppKit
import Foundation

@discardableResult
func require(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
    return true
}

let size = NSSize(width: 472, height: 536)
let gap: CGFloat = 14
let margin: CGFloat = 12
let visible = NSRect(x: 0, y: 0, width: 1200, height: 900)

let rightAnchor = NSRect(x: 120, y: 360, width: 92, height: 92)
let rightPlacement = PanelPlacementCalculator.place(
    near: rightAnchor,
    panelSize: size,
    visibleFrame: visible,
    gap: gap,
    margin: margin
)
require(rightPlacement.opensToRight, "uses right side when there is enough room")
require(rightPlacement.frame.minX == rightAnchor.maxX + gap, "right placement x")
require(rightPlacement.frame.midY == rightAnchor.midY, "right placement aligns to anchor center")

let leftAnchor = NSRect(x: 1080, y: 380, width: 92, height: 92)
let leftPlacement = PanelPlacementCalculator.place(
    near: leftAnchor,
    panelSize: size,
    visibleFrame: visible,
    gap: gap,
    margin: margin
)
require(!leftPlacement.opensToRight, "uses left side when right side would overflow")
require(leftPlacement.frame.maxX == leftAnchor.minX - gap, "left placement x")

let lowAnchor = NSRect(x: 120, y: 8, width: 92, height: 92)
let lowPlacement = PanelPlacementCalculator.place(
    near: lowAnchor,
    panelSize: size,
    visibleFrame: visible,
    gap: gap,
    margin: margin
)
require(lowPlacement.frame.minY >= visible.minY + margin, "low placement clamps to bottom margin")

print("PanelPlacementTests passed")
