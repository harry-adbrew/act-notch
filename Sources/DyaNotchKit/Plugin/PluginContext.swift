import Foundation
import os

/// Everything a plugin may ask of the host. Plugins never touch windows, screens or each other.
@MainActor
public protocol PluginContext: AnyObject {
    var storage: PluginStorage { get }
    var log: Logger { get }

    /// One-shot callback at a wall-clock date. It survives sleep: if the date passed while the Mac
    /// slept, it fires on wake. Re-scheduling the same id replaces the previous job. Ids are
    /// namespaced per plugin by the host.
    func schedule(at date: Date, id: String, _ fire: @escaping @MainActor () -> Void)
    func cancel(id: String)

    /// Briefly auto-expand the notch to show this plugin's `peekView`.
    func requestPeek(seconds: TimeInterval)

    /// Ask for the panel to accept keyboard focus (e.g. while a text field is being edited).
    func setWantsKeyboard(_ wants: Bool)
}
