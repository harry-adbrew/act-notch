import AppKit

/// Event monitors that only exist while the island is expanded, so they cost nothing when idle:
/// - a click anywhere outside the app → `onClickOutside`;
/// - Esc → `onEscape` (the key press is swallowed);
/// - a horizontal two-finger swipe over the panel → `onSwipe(+1 / -1)`.
@MainActor
final class ExpandedInputMonitor {
    static let escapeKeyCode: UInt16 = 53
    /// Horizontal travel (points) a swipe needs before it turns the page.
    static let swipeThreshold: CGFloat = 60

    var onClickOutside: () -> Void = {}
    var onEscape: () -> Void = {}
    /// +1 = next page, -1 = previous page.
    var onSwipe: (Int) -> Void = { _ in }

    private var monitors: [Any] = []
    private var swipeTravel: CGFloat = 0
    private weak var panel: NSWindow?

    func start(for panel: NSWindow) {
        stop()
        self.panel = panel

        // Global monitors never see our own windows' events, so any hit here is outside.
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { [weak self] _ in
            MainActor.assumeIsolated { self?.onClickOutside() }
        }) {
            monitors.append(monitor)
        }

        if let monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .scrollWheel], handler: { [weak self] event in
            // Local monitors run on the main thread; the box only satisfies the Sendable checker.
            let box = UncheckedSendable(event)
            return MainActor.assumeIsolated { UncheckedSendable(self?.handle(box.value) ?? box.value) }.value
        }) {
            monitors.append(monitor)
        }
    }

    func stop() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors = []
        swipeTravel = 0
    }

    /// Returns the event to pass it on, or nil to swallow it.
    private func handle(_ event: NSEvent) -> NSEvent? {
        switch event.type {
        case .keyDown where event.keyCode == Self.escapeKeyCode:
            onEscape()
            return nil
        case .scrollWheel where event.window === panel && event.hasPreciseScrollingDeltas:
            trackSwipe(event)
            return event
        default:
            return event
        }
    }

    private func trackSwipe(_ event: NSEvent) {
        if event.phase == .began { swipeTravel = 0 }
        if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) { swipeTravel += event.scrollingDeltaX }
        guard event.phase == .ended || event.phase == .cancelled else { return }
        if abs(swipeTravel) > Self.swipeThreshold { onSwipe(swipeTravel < 0 ? 1 : -1) }
        swipeTravel = 0
    }
}

/// Carries a non-Sendable value across an isolation boundary the compiler can't see is safe.
private struct UncheckedSendable<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}
