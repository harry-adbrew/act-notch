import AppKit

/// System events the island reacts to. Notifications only; nothing polls.
@MainActor
final class ScreenObserver {
    var onScreensChanged: () -> Void = {}
    /// Lock state or display sleep changed.
    var onSuspendChanged: () -> Void = {}
    var onWake: () -> Void = {}
    /// Active Space or frontmost app changed (re-check for fullscreen apps).
    var onSpaceChanged: () -> Void = {}

    private(set) var locked = false
    private(set) var screensAsleep = false
    private var tokens: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    /// True when the island should be hidden everywhere regardless of what is on screen.
    var systemHidesIsland: Bool { locked || screensAsleep }

    func start() {
        let app = NotificationCenter.default
        let workspace = NSWorkspace.shared.notificationCenter
        let distributed = DistributedNotificationCenter.default()

        observe(app, NSApplication.didChangeScreenParametersNotification) { $0.onScreensChanged() }

        observe(workspace, NSWorkspace.screensDidSleepNotification) { $0.screensAsleep = true; $0.onSuspendChanged() }
        observe(workspace, NSWorkspace.screensDidWakeNotification) { $0.screensAsleep = false; $0.onSuspendChanged() }
        observe(workspace, NSWorkspace.didWakeNotification) { $0.onWake() }
        observe(workspace, NSWorkspace.activeSpaceDidChangeNotification) { $0.onSpaceChanged() }
        observe(workspace, NSWorkspace.didActivateApplicationNotification) { $0.onSpaceChanged() }

        // Undocumented but long-standing distributed notifications.
        observe(distributed, Notification.Name("com.apple.screenIsLocked")) { $0.locked = true; $0.onSuspendChanged() }
        observe(distributed, Notification.Name("com.apple.screenIsUnlocked")) { $0.locked = false; $0.onSuspendChanged() }
    }

    private func observe(
        _ center: NotificationCenter,
        _ name: Notification.Name,
        _ handler: @escaping @MainActor (ScreenObserver) -> Void
    ) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                handler(self)
            }
        }
        tokens.append((center, token))
    }
}
