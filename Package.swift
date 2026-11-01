// swift-tools-version: 6.0
import PackageDescription

// Zero third-party dependencies by design (docs/HLD.md §9).
//
// Module graph:
//   DyaNotch (executable, main.swift only)
//     └─ DyaNotchHost (app logic: displays, window, input, state, UI, settings)
//          ├─ SpotifyPlugin ─┐
//          ├─ TimerPlugin  ──┼─ DyaNotchKit (public plugin SDK)
//          └─ TodoPlugin   ─┘
// Plugins can only see DyaNotchKit; that is the plugin boundary.
let package = Package(
    name: "DyaNotch",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "DyaNotch", targets: ["DyaNotch"]),
        .library(name: "DyaNotchKit", targets: ["DyaNotchKit"]),
    ],
    targets: [
        // MARK: SDK
        .target(name: "DyaNotchKit"),

        // MARK: Built-in plugins
        .target(name: "SpotifyPlugin", dependencies: ["DyaNotchKit"], path: "Sources/Plugins/SpotifyPlugin"),
        .target(name: "TimerPlugin", dependencies: ["DyaNotchKit"], path: "Sources/Plugins/TimerPlugin"),
        .target(name: "TodoPlugin", dependencies: ["DyaNotchKit"], path: "Sources/Plugins/TodoPlugin"),

        // MARK: Host
        .target(
            name: "DyaNotchHost",
            dependencies: ["DyaNotchKit", "SpotifyPlugin", "TimerPlugin", "TodoPlugin"]
        ),
        .executableTarget(name: "DyaNotch", dependencies: ["DyaNotchHost"]),

        // MARK: Tests
        .testTarget(name: "DyaNotchKitTests", dependencies: ["DyaNotchKit"]),
        .testTarget(name: "PluginTests", dependencies: ["DyaNotchKit", "TimerPlugin", "TodoPlugin", "SpotifyPlugin"]),
        .testTarget(name: "DyaNotchHostTests", dependencies: ["DyaNotchHost", "DyaNotchKit"]),
    ]
)
