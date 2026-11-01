import DyaNotchKit
import Foundation
import os

/// The host side of `PluginContext`. Namespaces scheduler ids, storage directories and log
/// subsystems per plugin, so plugins can never collide with each other.
@MainActor
final class HostPluginContext: PluginContext {
    let storage: PluginStorage
    let log: Logger
    private let pluginID: String
    private weak var registry: PluginRegistry?

    init(manifest: PluginManifest, registry: PluginRegistry) {
        pluginID = manifest.id
        self.registry = registry
        storage = PluginStorage(directory: registry.storageRoot.appendingPathComponent(manifest.id, isDirectory: true))
        log = Logger(subsystem: "io.dyanotch.plugin.\(manifest.id)", category: "plugin")
    }

    /// Every scheduler job of a plugin starts with this prefix.
    static func jobPrefix(for pluginID: String) -> String { "\(pluginID)." }

    func schedule(at date: Date, id: String, _ fire: @escaping @MainActor () -> Void) {
        registry?.scheduler.schedule(id: Self.jobPrefix(for: pluginID) + id, at: date, fire)
    }

    func cancel(id: String) {
        registry?.scheduler.cancel(id: Self.jobPrefix(for: pluginID) + id)
    }

    func requestPeek(seconds: TimeInterval) {
        registry?.onPeek(pluginID, seconds)
    }

    func setWantsKeyboard(_ wants: Bool) {
        registry?.onWantsKeyboard(wants)
    }
}
