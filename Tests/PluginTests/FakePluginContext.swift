import DyaNotchKit
import Foundation
import os

/// A `PluginContext` driven by a fake clock: jobs fire only when a test calls `advance(by:)`.
@MainActor
final class FakePluginContext: PluginContext {
    var now: Date
    lazy var scheduler = OneShotScheduler(now: { [unowned self] in self.now }, armsTimers: false)
    let storage: PluginStorage
    let log = Logger(subsystem: "io.dyanotch.tests", category: "fake")
    private(set) var peeks: [TimeInterval] = []
    private(set) var wantsKeyboard = false

    init(now: Date = .now) {
        self.now = now
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        storage = PluginStorage(directory: directory)
    }

    func advance(by seconds: TimeInterval) {
        now += seconds
        scheduler.fireDue()
    }

    func schedule(at date: Date, id: String, _ fire: @escaping @MainActor () -> Void) {
        scheduler.schedule(id: id, at: date, fire)
    }

    func cancel(id: String) { scheduler.cancel(id: id) }
    func requestPeek(seconds: TimeInterval) { peeks.append(seconds) }
    func setWantsKeyboard(_ wants: Bool) { wantsKeyboard = wants }
}
