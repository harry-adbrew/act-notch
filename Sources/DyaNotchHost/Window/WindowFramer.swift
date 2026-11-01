import AppKit

/// Resizes the panel only on presentation transitions, never per animation frame:
/// - growing applies immediately, before the opening spring runs;
/// - shrinking waits until the closing spring has settled, and is skipped if a newer change arrived.
///
/// Because the window is never larger than the island needs, clicks around it fall straight through
/// to the menu bar.
@MainActor
final class WindowFramer {
    /// Long enough for `DN.Motion.close` to settle.
    static let shrinkDelay: TimeInterval = 0.5

    private let window: NSWindow
    private var generation = 0

    init(window: NSWindow) {
        self.window = window
    }

    func setFrame(_ target: CGRect, deferShrink: Bool) {
        generation += 1
        let current = window.frame
        let shrinks = target.width < current.width || target.height < current.height

        guard shrinks && deferShrink else {
            window.setFrame(target, display: true)
            return
        }

        // Grow whichever dimension needs it now; apply the final frame once the spring settles.
        let interim = target.union(current)
        if interim != current { window.setFrame(interim, display: true) }

        let expected = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.shrinkDelay) { [weak self] in
            guard let self, self.generation == expected else { return }
            self.window.setFrame(target, display: true)
        }
    }
}
