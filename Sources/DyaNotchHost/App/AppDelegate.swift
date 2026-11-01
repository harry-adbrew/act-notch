import AppKit
import DyaNotchKit

/// Wires the long-lived pieces together. Contains no logic of its own:
/// plugins → `PluginRegistry`, screens → `DisplayManager`, system events → `ScreenObserver`.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let registry = PluginRegistry()
    private let settings = AppSettings(manifests: PluginRegistry.manifests)
    private let observer = ScreenObserver()
    private lazy var settingsWindow = SettingsWindowPresenter(settings: settings, registry: registry)
    private lazy var displays = DisplayManager(
        registry: registry,
        settings: settings,
        observer: observer,
        openSettings: { [weak self] in self?.settingsWindow.show() }
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        connectPluginsToDisplays()
        connectSystemEvents()
        settings.onChange = { [weak self] in self?.applySettings() }

        registry.apply(enabled: settings.enabledPlugins)
        displays.rebuild()
    }

    func applicationWillTerminate(_ notification: Notification) {
        registry.flushAll()
    }

    // MARK: - Wiring

    private func connectPluginsToDisplays() {
        registry.onPeek = { [weak self] pluginID, seconds in
            self?.displays.forEach { $0.peek(pluginID, seconds: seconds) }
        }
        registry.onWantsKeyboard = { [weak self] wants in
            self?.displays.forEach { $0.setEditing(wants) }
        }
    }

    private func connectSystemEvents() {
        observer.onScreensChanged = { [weak self] in self?.displays.rebuild() }
        observer.onSuspendChanged = { [weak self] in self?.displays.updateSuspension() }
        observer.onSpaceChanged = { [weak self] in self?.displays.updateSuspension() }
        observer.onWake = { [weak self] in
            guard let self else { return }
            // Deadlines that passed while asleep fire now; hover state from before sleep is discarded.
            registry.scheduler.rearm()
            displays.forEach { $0.resetTransientState() }
            displays.updateSuspension()
        }
        observer.start()
    }

    /// Idempotent: safe to call after any settings change.
    private func applySettings() {
        registry.apply(enabled: settings.enabledPlugins)
        displays.rebuild()
        displays.forEach { $0.applySettings() }
    }
}
