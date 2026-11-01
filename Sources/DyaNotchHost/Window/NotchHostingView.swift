import AppKit
import SwiftUI

/// Hosting view for the island:
/// - hover via an `.activeAlways` tracking area (no polling, works while the app is inactive);
/// - the first click counts even though the panel is not key;
/// - right-click shows the context menu;
/// - never resizes the window (the controller owns the frame).
final class NotchHostingView<Content: View>: NSHostingView<Content> {
    var onHover: (_ inside: Bool) -> Void = { _ in }
    var menuProvider: () -> NSMenu? = { nil }

    required init(rootView: Content) {
        super.init(rootView: rootView)
        sizingOptions = []
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    @MainActor required dynamic init?(coder: NSCoder) { fatalError("Not used") }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseEntered(with event: NSEvent) { onHover(true) }
    override func mouseExited(with event: NSEvent) { onHover(false) }
    override func menu(for event: NSEvent) -> NSMenu? { menuProvider() }
}
