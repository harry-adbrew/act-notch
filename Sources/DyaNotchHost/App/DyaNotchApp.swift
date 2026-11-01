import AppKit

/// Entry point used by the `DyaNotch` executable.
public enum DyaNotchApp {
    @MainActor
    public static func run() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        // `NSApplication.delegate` is weak; keep the delegate alive for the life of the run loop.
        withExtendedLifetime(delegate) { app.run() }
    }
}
