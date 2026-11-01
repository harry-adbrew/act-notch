import AppKit

/// Right-click menu on the island: Settings… and Quit.
@MainActor
enum NotchContextMenu {
    static func make(openSettings: @escaping @MainActor () -> Void) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(ClosureMenuItem(title: "Settings…", keyEquivalent: ",", action: openSettings))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit DyaNotch", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }
}

/// An `NSMenuItem` that runs a closure, so callers don't need an `@objc` target.
private final class ClosureMenuItem: NSMenuItem {
    private let handler: @MainActor () -> Void

    init(title: String, keyEquivalent: String, action handler: @escaping @MainActor () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(fire), keyEquivalent: keyEquivalent)
        target = self
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError("Not used") }

    @objc private func fire() {
        MainActor.assumeIsolated(handler)
    }
}
