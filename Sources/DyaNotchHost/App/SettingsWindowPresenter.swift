import AppKit
import SwiftUI

/// Lazily creates and shows the single Settings window.
@MainActor
final class SettingsWindowPresenter {
    private let settings: AppSettings
    private let registry: PluginRegistry
    private var window: NSWindow?

    init(settings: AppSettings, registry: PluginRegistry) {
        self.settings = settings
        self.registry = registry
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        // An agent app must activate itself for its window to take focus.
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "DyaNotch Settings"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: SettingsView(settings: settings, registry: registry))
        window.center()
        return window
    }
}
