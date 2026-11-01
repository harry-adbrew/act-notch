import AppKit

/// Keeps one `NotchController` per target screen and decides which screens are suspended.
@MainActor
final class DisplayManager {
    private let registry: PluginRegistry
    private let settings: AppSettings
    private let observer: ScreenObserver
    private let openSettings: () -> Void
    private var controllers: [CGDirectDisplayID: NotchController] = [:]

    init(registry: PluginRegistry, settings: AppSettings, observer: ScreenObserver, openSettings: @escaping () -> Void) {
        self.registry = registry
        self.settings = settings
        self.observer = observer
        self.openSettings = openSettings
    }

    func forEach(_ body: (NotchController) -> Void) {
        controllers.values.forEach(body)
    }

    /// The notched built-in screen (or the main screen) by default; every screen when "all displays" is on.
    private var targetScreens: [NSScreen] {
        if settings.allDisplays { return NSScreen.screens }
        if let notched = NSScreen.screens.first(where: \.hasNotch) { return [notched] }
        return NSScreen.main.map { [$0] } ?? []
    }

    /// Diffs controllers against the target screens: removes, updates and creates as needed.
    func rebuild() {
        let screens = targetScreens
        let wanted = Set(screens.map(\.displayID))

        for (id, controller) in controllers where !wanted.contains(id) {
            controller.close()
            controllers[id] = nil
        }
        for screen in screens {
            if let existing = controllers[screen.displayID] {
                // Only a real geometry change invalidates hover/peek state; a settings toggle must not.
                if existing.update(screen: screen) { existing.resetTransientState() }
            } else {
                controllers[screen.displayID] = NotchController(
                    screen: screen, registry: registry, settings: settings, openSettings: openSettings
                )
            }
        }
        updateSuspension()
    }

    /// Hidden while locked or asleep, and (if enabled) while a fullscreen app covers that screen.
    func updateSuspension() {
        for screen in targetScreens {
            guard let controller = controllers[screen.displayID] else { continue }
            let fullscreen = settings.hideInFullscreen && FullscreenDetector.hasFullscreenApp(on: screen)
            controller.setSuspended(observer.systemHidesIsland || fullscreen)
        }
    }
}
