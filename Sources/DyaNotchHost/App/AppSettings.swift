import DyaNotchKit
import Foundation
import Observation
import ServiceManagement

/// User settings, persisted in UserDefaults under `dn.*`. Every change calls `onChange`, which the
/// app delegate turns into an idempotent re-apply.
@MainActor
@Observable
final class AppSettings {
    @ObservationIgnored var onChange: () -> Void = {}
    @ObservationIgnored private let defaults: UserDefaults

    var enabledPlugins: Set<String> { didSet { save(Array(enabledPlugins).sorted(), "enabledPlugins") } }
    var hoverToExpand: Bool { didSet { save(hoverToExpand, "hoverToExpand") } }
    var hideInFullscreen: Bool { didSet { save(hideInFullscreen, "hideInFullscreen") } }
    var hideFromCapture: Bool { didSet { save(hideFromCapture, "hideFromCapture") } }
    var allDisplays: Bool { didSet { save(allDisplays, "allDisplays") } }

    init(defaults: UserDefaults = .standard, manifests: [PluginManifest]) {
        self.defaults = defaults
        if let stored = defaults.array(forKey: "dn.enabledPlugins") as? [String] {
            enabledPlugins = Set(stored)
        } else {
            enabledPlugins = Set(manifests.filter(\.defaultEnabled).map(\.id))
        }
        hoverToExpand = defaults.object(forKey: "dn.hoverToExpand") as? Bool ?? true
        hideInFullscreen = defaults.object(forKey: "dn.hideInFullscreen") as? Bool ?? true
        hideFromCapture = defaults.object(forKey: "dn.hideFromCapture") as? Bool ?? true
        allDisplays = defaults.object(forKey: "dn.allDisplays") as? Bool ?? false
    }

    private func save(_ value: Any, _ key: String) {
        defaults.set(value, forKey: "dn.\(key)")
        onChange()
    }

    // MARK: Launch at login (needs the bundled .app; fails harmlessly when run via `swift run`)

    var launchAtLogin: Bool {
        get { access(keyPath: \.launchAtLogin); return SMAppService.mainApp.status == .enabled }
        set {
            withMutation(keyPath: \.launchAtLogin) {
                do {
                    if newValue { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                    loginError = nil
                } catch {
                    loginError = error.localizedDescription
                }
            }
        }
    }

    var loginError: String?
}
