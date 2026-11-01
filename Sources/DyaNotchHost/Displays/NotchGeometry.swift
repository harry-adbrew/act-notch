import AppKit

/// Where the island lives on one screen. A plain value, so layout code is testable without a display.
struct NotchGeometry: Equatable {
    /// Closed size used on screens without a notch (the floating pill).
    static let pillSize = CGSize(width: 110, height: 30)
    /// Hover strip at the top edge of a pill screen while nothing is shown.
    static let hotEdgeSize = CGSize(width: 160, height: 3)
    /// Gap between the menu bar and a floating pill.
    static let pillGap: CGFloat = 4
    /// Extra width so the hardware notch's edge never peeks out from under the island.
    static let notchBleed: CGFloat = 4

    let displayID: CGDirectDisplayID
    let screenFrame: CGRect
    let visibleFrame: CGRect
    let hasNotch: Bool
    /// The closed island body: the hardware notch (+ bleed), or the virtual pill.
    let notchSize: CGSize

    init(displayID: CGDirectDisplayID, screenFrame: CGRect, visibleFrame: CGRect, hardwareNotch: CGSize?) {
        self.displayID = displayID
        self.screenFrame = screenFrame
        self.visibleFrame = visibleFrame
        if let hardwareNotch {
            hasNotch = true
            notchSize = CGSize(width: hardwareNotch.width + Self.notchBleed, height: hardwareNotch.height)
        } else {
            hasNotch = false
            notchSize = Self.pillSize
        }
    }

    init(screen: NSScreen) {
        self.init(
            displayID: screen.displayID,
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            hardwareNotch: screen.hardwareNotchSize
        )
    }

    /// Window frame for a canvas size.
    /// - Notched screens: pinned to the very top, so the anti-aliased top edge sits off-screen.
    /// - Pill screens: floating just under the menu bar, or a thin hot-edge strip while hidden.
    func windowFrame(canvas: CGSize, hidden: Bool) -> CGRect {
        if hasNotch {
            return centered(canvas, top: screenFrame.maxY)
        }
        if hidden {
            return centered(Self.hotEdgeSize, top: screenFrame.maxY)
        }
        return centered(canvas, top: visibleFrame.maxY - Self.pillGap)
    }

    private func centered(_ size: CGSize, top: CGFloat) -> CGRect {
        CGRect(x: screenFrame.midX - size.width / 2, y: top - size.height, width: size.width, height: size.height)
    }
}
