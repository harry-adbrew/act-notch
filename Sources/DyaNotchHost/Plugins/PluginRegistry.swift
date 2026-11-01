import DyaNotchKit
import Foundation
import Observation
import os

/// Owns plugin instances and the shared scheduler. One registry serves every screen.
@MainActor
@Observable
final class PluginRegistry {
    struct Entry {
        let manifest: PluginManifest
        let plugin: any NotchPlugin
    }

    /// Activated plugins, in page order.
    private(set) var active: [Entry] = []
    /// Plugins whose `activate` threw, with the error message (shown in Settings).
    private(set) var failures: [String: String] = [:]

    @ObservationIgnored let scheduler = OneShotScheduler()
    @ObservationIgnored let storageRoot: URL
    @ObservationIgnored var onPeek: (_ pluginID: String, _ seconds: TimeInterval) -> Void = { _, _ in }
    @ObservationIgnored var onWantsKeyboard: (Bool) -> Void = { _ in }

    @ObservationIgnored private let types: [any NotchPlugin.Type]
    @ObservationIgnored private var contexts: [String: HostPluginContext] = [:]
    @ObservationIgnored private let log = Logger(subsystem: "io.dyanotch.app", category: "registry")

    init(types: [any NotchPlugin.Type] = BuiltInPlugins.all, storageRoot: URL = PluginRegistry.defaultStorageRoot) {
        self.types = types
        self.storageRoot = storageRoot
    }

    static var manifests: [PluginManifest] { BuiltInPlugins.all.map { $0.manifest } }

    static var defaultStorageRoot: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DyaNotch", isDirectory: true)
    }

    func plugin(_ id: String) -> (any NotchPlugin)? {
        active.first { $0.manifest.id == id }?.plugin
    }

    // MARK: - Enable / disable

    /// Activates newly enabled plugins and deactivates disabled ones. Idempotent.
    func apply(enabled: Set<String>) {
        for entry in active where !enabled.contains(entry.manifest.id) {
            deactivate(entry)
        }
        for type in types where enabled.contains(type.manifest.id) && plugin(type.manifest.id) == nil {
            activate(type)
        }
    }

    private func activate(_ type: any NotchPlugin.Type) {
        let manifest = type.manifest
        let instance = type.init()
        let context = HostPluginContext(manifest: manifest, registry: self)
        contexts[manifest.id] = context
        failures[manifest.id] = nil
        active.append(Entry(manifest: manifest, plugin: instance))
        active.sort { pageIndex($0.manifest.id) < pageIndex($1.manifest.id) }

        Task {
            do {
                try await instance.activate(context)
                log.info("activated \(manifest.id, privacy: .public)")
            } catch {
                // Failure isolation: a plugin that cannot start is switched off; the app carries on.
                log.error("activate failed for \(manifest.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
                failures[manifest.id] = error.localizedDescription
                active.removeAll { $0.manifest.id == manifest.id }
                contexts[manifest.id] = nil
            }
        }
    }

    private func deactivate(_ entry: Entry) {
        let id = entry.manifest.id
        entry.plugin.deactivate()
        scheduler.cancelAll(prefix: HostPluginContext.jobPrefix(for: id))
        contexts[id]?.storage.flush()
        contexts[id] = nil
        active.removeAll { $0.manifest.id == id }
        log.info("deactivated \(id, privacy: .public)")
    }

    private func pageIndex(_ id: String) -> Int {
        types.firstIndex { $0.manifest.id == id } ?? .max
    }

    // MARK: - Activities

    /// Reads every plugin's `activity` (so SwiftUI tracks them) and picks primary and secondary.
    func resolve(now: Date = .now) -> ActivityArbiter.Resolution {
        let candidates = active.compactMap { entry in
            entry.plugin.activity.map { ActivityCandidate(pluginID: entry.manifest.id, activity: $0) }
        }
        return ActivityArbiter.resolve(candidates, now: now)
    }

    func flushAll() {
        contexts.values.forEach { $0.storage.flush() }
    }
}
