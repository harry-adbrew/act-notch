import DyaNotchKit
import SpotifyPlugin
import TimerPlugin
import TodoPlugin

/// The plugins that ship with the app, in page order.
/// Adding a plugin = a new target in Package.swift + one line here (docs/LLD.md §2).
@MainActor
enum BuiltInPlugins {
    static let all: [any NotchPlugin.Type] = [
        SpotifyPlugin.self,
        TimerPlugin.self,
        TodoPlugin.self,
    ]
}
