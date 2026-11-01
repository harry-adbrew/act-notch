import AppKit

/// Borderless, non-activating, transparent panel that floats over the menu bar on every Space,
/// including fullscreen ones. Public API only (no private CGS/SkyLight spaces).
final class NotchPanel: NSPanel {
    /// Accept key status only while expanded, so text fields work but focus is never stolen otherwise.
    var allowsKey = false

    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        isFloatingPanel = true
        level = .statusBar + 1
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        hidesOnDeactivate = false
        animationBehavior = .none
        appearance = NSAppearance(named: .darkAqua)
    }

    override var canBecomeKey: Bool { allowsKey }
    override var canBecomeMain: Bool { false }
}
