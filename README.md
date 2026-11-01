# DyaNotch

A lightweight, plugin-based Dynamic Island for the MacBook notch. Native SwiftUI + AppKit, zero third-party dependencies, about 0% CPU when idle.

Built-in plugins:
- **Spotify:** auto-detected. Shows artwork, an equalizer and controls.
- **Timers:** several at once. They're based on end dates, so they survive sleep.
- **Todos:** "call mom in 10m". Due items peek from the notch.

## Run
```sh
scripts/bundle.sh          # release build → ~/Applications/DyaNotch.app (ad-hoc signed)
open ~/Applications/DyaNotch.app
scripts/test.sh            # budget guard + swift-testing suite
```
Requires macOS 14+ on Apple Silicon. Swift 6 Command Line Tools are enough; Xcode is not needed.

Hover over the notch to expand it. Right-click it, or use the gear in the expanded view, for Settings and Quit.

## Layout
```
Sources/DyaNotchKit    public plugin SDK (contract, runtime, design tokens, components)
Sources/DyaNotchHost   the app: displays, window, input, state, UI, settings
Sources/Plugins/*      Spotify, Timer, Todo (each depends only on the SDK)
Sources/DyaNotch       main.swift
```

## Docs
- [PRD](docs/PRD.md): what and why, budgets, milestones
- [HLD](docs/HLD.md): components, state machine, event sources, plugin model
- [LLD](docs/LLD.md): contracts, window and input details, per-plugin internals, sequences
- [Design system](docs/DESIGN.md): tokens, states, layouts, REA reference findings

## Writing a plugin
Copy the shape of an existing plugin (`<Name>Plugin.swift`, `<Name>Plugin+Views.swift`, `Model/`, `Views/`). Add a target that depends only on `DyaNotchKit`, write an `@Observable` class conforming to `NotchPlugin`, and register it in `BuiltInPlugins.all`. See [LLD §1–2](docs/LLD.md).
