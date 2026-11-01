import DyaNotchKit
import Foundation
import Observation
import Testing
@testable import DyaNotchHost

/// Minimal plugin: schedules one far-future job on activation; can be told to fail.
@MainActor
@Observable
final class ProbePlugin: NotchPlugin {
    static let manifest = PluginManifest(id: "probe", name: "Probe", symbol: "circle", summary: "")
    nonisolated(unsafe) static var failActivation = false
    var activity: LiveActivity? { nil }

    init() {}

    func activate(_ context: PluginContext) async throws {
        if Self.failActivation { throw CocoaError(.featureUnsupported) }
        context.schedule(at: .now + 3600, id: "job") {}
    }
}

@MainActor
@Suite(.serialized) struct PluginRegistryTests {
    private func makeRegistry() -> PluginRegistry {
        PluginRegistry(
            types: [ProbePlugin.self],
            storageRoot: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        )
    }

    /// Lets the registry's activation Task run.
    private func settle() async {
        for _ in 0..<5 { await Task.yield() }
    }

    @Test func disablingCancelsThePluginsJobs() async {
        ProbePlugin.failActivation = false
        let registry = makeRegistry()

        registry.apply(enabled: ["probe"])
        await settle()
        #expect(registry.plugin("probe") != nil)
        #expect(registry.scheduler.scheduledIDs == ["probe.job"])

        registry.apply(enabled: [])
        #expect(registry.plugin("probe") == nil)
        #expect(registry.scheduler.scheduledIDs.isEmpty)
    }

    @Test func failedActivationIsIsolatedAndReported() async {
        ProbePlugin.failActivation = true
        defer { ProbePlugin.failActivation = false }
        let registry = makeRegistry()

        registry.apply(enabled: ["probe"])
        await settle()

        #expect(registry.plugin("probe") == nil)
        #expect(registry.failures["probe"] != nil)
    }
}
