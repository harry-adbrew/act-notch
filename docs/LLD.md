# DyaNotch: Low-Level Design

Source of truth is the code. This document explains the contracts and the non-obvious decisions.

## 1. Modules and layout (enforced by SwiftPM)
```
DyaNotch (executable: main.swift only)
  └─▶ DyaNotchHost (all app logic, testable)
        ├─▶ SpotifyPlugin ─┐
        ├─▶ TimerPlugin  ──┼─▶ DyaNotchKit (public SDK) ─▶ SwiftUI / AppKit / Foundation / os
        └─▶ TodoPlugin   ─┘
Tests: DyaNotchKitTests ─▶ Kit · PluginTests ─▶ plugins · DyaNotchHostTests ─▶ Host
```
A plugin target cannot import the host; that is the plugin boundary. Each file holds one type (or one
type plus small private helpers), named after the file.

**`Sources/DyaNotchKit/`**: the SDK

| Folder | Files |
|---|---|
| `Plugin/` | `NotchPlugin` (contract + defaults), `PluginManifest`, `PluginContext`, `NotchViewContext` |
| `Activity/` | `LiveActivity`; `ActivityArbiter` + `ActivityCandidate` |
| `Runtime/` | `OneShotScheduler`, `PluginStorage` |
| `Parsing/` | `DurationParser` |
| `Design/` | `DesignTokens` (`DN`), `Color+Hex`, `NotchContentTransition` |
| `Components/` | `NotchIconButton`, `NotchChip`, `NotchProgressBar`, `NotchRing`, `PressableStyle` |

**`Sources/DyaNotchHost/`**: the app

| Folder | Files | Responsibility |
|---|---|---|
| `App/` | `DyaNotchApp`, `AppDelegate`, `AppSettings`, `SettingsWindowPresenter` | Entry point and wiring only; settings persistence |
| `Plugins/` | `BuiltInPlugins`, `PluginRegistry`, `HostPluginContext` | Which plugins exist; activation; per-plugin namespacing |
| `Displays/` | `DisplayManager`, `ScreenObserver`, `FullscreenDetector`, `NotchGeometry`, `NSScreen+Notch` | Which screens get an island; system events; where the island sits |
| `State/` | `NotchStore`, `Presentation`, `NotchLayout` | Per-screen UI state and pure size and radius maths |
| `Window/` | `NotchController`, `NotchPanel`, `NotchHostingView`, `WindowFramer` | One controller per screen; the panel; frame policy |
| `Input/` | `HoverIntent`, `ExpandedInputMonitor`, `NotchContextMenu` | Hover timing; click-outside, Esc and swipe; right-click menu |
| `UI/` | `NotchRootView`, `IslandShape`, `CompactWings`, `PeekContent`, `ExpandedView`, `ExpandedHeader`, `SecondaryBadge`, `NotchActions` | SwiftUI tree |
| `Settings/` | `SettingsView` | Settings form |

**`Sources/Plugins/<Name>Plugin/`**: same shape for every plugin

| Path | Contents |
|---|---|
| `<Name>Plugin.swift` | State, lifecycle, activity, commands, scheduling |
| `<Name>Plugin+Views.swift` | The four view builders (compact leading and trailing, peek, expanded) |
| `Model/` | Value types (`TimerItem`, `Todo`, `SpotifyTrack`) |
| `Services/` | Side-effecting helpers (Spotify: `SpotifyMonitor`, `SpotifyAppleEvents`, `ArtworkLoader`) |
| `Parsing/` | Text parsing (Todo: `QuickAddParser`) |
| `Views/` | SwiftUI views, one per file |

## 2. Plugin SDK
```swift
@MainActor public protocol NotchPlugin: AnyObject, Observable {
    static var manifest: PluginManifest { get }   // id, name, symbol, summary, defaultEnabled
    init()                                        // cheap; no I/O
    func activate(_ context: PluginContext) async throws
    func deactivate()                             // default: no-op
    var activity: LiveActivity? { get }           // nil = nothing for the compact island
    func compactLeading(_ ctx: NotchViewContext) -> AnyView?   // defaults: nil
    func compactTrailing(_ ctx: NotchViewContext) -> AnyView?
    func peekView(_ ctx: NotchViewContext) -> AnyView?
    func expandedView(_ ctx: NotchViewContext) -> AnyView?     // nil = no page
}

public struct LiveActivity { id, priority: .ambient/.normal/.urgent, since: Date, expiresAt: Date?, tint: Color? }

@MainActor public protocol PluginContext: AnyObject {
    var storage: PluginStorage { get }            // <AppSupport>/DyaNotch/<plugin-id>/<name>.json
    var log: Logger { get }                       // subsystem io.dyanotch.plugin.<id>
    func schedule(at: Date, id: String, _ fire: @escaping @MainActor () -> Void)
    func cancel(id: String)
    func requestPeek(seconds: TimeInterval)
    func setWantsKeyboard(_ wants: Bool)
}
```

**Plugin rules**
1. The class is `@Observable`. The host calls `activity` and the view builders inside SwiftUI bodies, so Observation tracks exactly the properties they read.
2. **No repeating timers, no `Task.sleep` loops.** Anything that changes over time is derived in a view: `TimelineView(.periodic…)` or `Text(timerInterval:)`. When a threshold needs crossing (a todo becoming "soon"), schedule a one-shot that bumps an observed property.
3. Views are built when shown and thrown away afterwards. Keep state in the plugin.
4. Use `matchedGeometryEffect(id:, in: ctx.namespace)` with a plugin-prefixed id for elements shared between compact and expanded views.
5. Use `DN` tokens and the `Components/` primitives; don't add new colours or fonts.

**Adding a plugin:** create `Sources/Plugins/<Name>Plugin/` with the layout above, add a target depending on `DyaNotchKit` in `Package.swift` (and to `DyaNotchHost`'s dependencies), then add `<Name>Plugin.self` to `BuiltInPlugins.all`. Nothing else in the host changes.

## 3. Host runtime

### 3.1 `PluginRegistry`
- `apply(enabled:)` diffs against `active`.
  - Removed plugins: `deactivate()`, cancel their scheduler jobs (`"<id>."` prefix), flush storage.
  - Added plugins: `init()` → `HostPluginContext` → `Task { try await activate(ctx) }`. If it throws, the plugin is removed from `active` and the error appears in `failures` (shown in Settings).
- `resolve(now:)` reads every `plugin.activity` and calls `ActivityArbiter.resolve`, which returns a `Resolution { primary, secondary }`.
- `HostPluginContext` namespaces scheduler ids (`"<plugin>.<id>"`), storage directories and log subsystems.

### 3.2 `ActivityArbiter`
Filter out expired activities, then sort by `priority` (descending), then `since` (descending), then plugin id. The first is the **primary** (owns the wings); the second is the **secondary** (a 28 pt detached circle showing its `compactLeading`).

### 3.3 `OneShotScheduler`
- `jobs: [id: (date, fire, DispatchSourceTimer)]`. Each job arms `timer.schedule(wallDeadline: .now() + delay, leeway: 100ms)` on the main queue.
- A *wall* deadline is what makes it sleep-safe: a deadline that passes during sleep fires right after wake.
- `rearm()` (called on `didWakeNotification`) fires anything overdue and re-arms the rest, as a second line of defence.
- Tests construct it with `armsTimers: false` and a fake clock, and drive it through `fireDue()`.

### 3.4 `PluginStorage`
- Encodes on the calling thread. Writes go through a serial utility queue, coalesced (default 300 ms), with `Data.write(.atomic)`.
- `load` checks the pending buffer before disk, so a read straight after a save sees the new value.
- `flush()` runs on deactivate and on quit. Dates are ISO-8601 (whole seconds, readable files).
- A file that exists but fails to decode (corrupt, or from an incompatible version) is moved to `<name>.corrupt-<unix-time>.json` and logged, so the plugin starts empty without the next save destroying the old data. Encode and write errors are logged, not swallowed.

### 3.5 `NotchStore` and `Presentation`
```
presentation = suspended            → .hidden
             | mode == .expanded    → .expanded
             | peekPluginID != nil  → .peek
             | primary != nil       → .compact
             | hasNotch ? .closed : .hidden
```
`NotchLayout` maps a presentation to the body size, the radii (top flare, bottom) and the window canvas:

| Presentation | Body size | Radii (notch) | Radii (pill) |
|---|---|---|---|
| closed | notch (w+4, safe-area h) | 6 / 10 | 0 / h/2 |
| compact | notch.w + 2·wing, h (wing = h+4) | 6 / 14 | 0 / h/2 |
| peek | max(compact.w, 380), h+40 | 10 / 18 | 0 / 18 |
| expanded | max(560, notch.w+300), h+156 | 19 / 24 | 0 / 24 |

The canvas adds 24×12 pt for spring overshoot in peek and expanded, and 2×(28+6) pt for the secondary badge in compact.

## 4. Window and input

### 4.1 `NotchPanel`
- `NSPanel([.borderless, .nonactivatingPanel])`.
- Level `.statusBar + 1`.
- Behaviours `[.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]`.
- Clear, non-opaque, no shadow, `animationBehavior = .none`, dark appearance.
- `canBecomeKey` returns `allowsKey`, which is true only while expanded.
- `sharingType = .none` when "hide from capture" is on.

### 4.2 Frame management (decided against the earlier "fixed big canvas" plan)
A fixed transparent window larger than the island would block menu-bar clicks around the notch. Instead, `NotchController.placeWindow`:
- **grows** the frame immediately when the new canvas is larger (before the spring runs);
- **shrinks** only after 0.5 s (once the close spring settles), and only if no newer transition happened (a generation counter);
- is pinned so `maxY == screen.maxY` (notch screens) or 4 pt under the menu bar (pill screens). A hidden pill screen keeps a 160×3 pt "hot edge" strip at the top centre, so hover still opens it.

`NSHostingView.sizingOptions = []`, so SwiftUI never resizes the window by itself.

### 4.3 Pointer and keyboard
| Input | Mechanism | Behaviour |
|---|---|---|
| Hover | `NSTrackingArea([.mouseEnteredAndExited, .activeAlways, .inVisibleRect])` on the hosting view | Enter: open after 120 ms (cancelled on exit). Exit while expanded: close after 300 ms, unless `store.editing` |
| Click | `onTapGesture` on the island | Expands; `acceptsFirstMouse = true` makes the first click count |
| Right-click | `menu(for:)` | Settings…, Quit |
| Click outside | Global `leftMouseDown/rightMouseDown` monitor, installed in `expand()` and removed in `collapse()` | Collapses |
| Esc / swipe | Local `keyDown`/`scrollWheel` monitor, expanded only | Esc collapses. A horizontal precise scroll over 60 pt between `.began` and `.ended` turns the page |
| Keyboard | `allowsKey` on expand | On collapse, if the panel is key: resign and re-activate the app that was frontmost before expanding |
| Haptic | `NSHapticFeedbackManager` `.alignment` | On expand |

### 4.4 System events (`ScreenObserver`)
| Event | Action |
|---|---|
| Screen parameters changed | `rebuildControllers()`: diff by `CGDirectDisplayID`, reuse controllers, update geometry, reset hover |
| Screens sleep/wake, lock/unlock | `setSuspended`: collapse and `orderOut`. Every view is torn down, so no `TimelineView` runs |
| System wake | `scheduler.rearm()`, `resetTransientState()` on every controller |
| Space change / app activation | `hasFullscreenApp(on:)`: one `CGWindowListCopyWindowInfo` call, comparing frontmost-app layer-0 window bounds against the screen. Bounds need no Screen Recording permission |

## 5. Plugins

### 5.1 Spotify
```
NSWorkspace didLaunch(com.spotify.client) ─▶ subscribe DistributedNotificationCenter
    "com.spotify.client.PlaybackStateChanged" ─▶ SpotifyTrack(notification:) ─▶ apply()
        new track id? ─▶ ArtworkLoader (oEmbed → thumbnail → 160 px + 1×1 average tint) ─▶ peek 2.5 s
NSWorkspace didTerminate ─▶ unsubscribe, track = nil
activate() while Spotify already running ─▶ one Apple Events read of the current track
```
- **Notification payload:** `Name`, `Artist`, `Track ID`, `Player State` (Playing/Paused/Stopped), `Playback Position` (seconds), `Duration` (**milliseconds**).
- **Activity:** `.ambient`, and only while playing.
- **Elapsed time:** `position + (now - positionAt)` while playing, computed in a 1 Hz `TimelineView` that exists only on the expanded page.
- **Commands:** raw Apple Events built from Spotify's `.sdef` codes: `spfy/PlPs` (play/pause), `spfy/Next`, `spfy/Prev`, and `core/setd` on property `pPos` (seek). The startup read uses `core/getd` on `pPlS`, `pPos` and the current track's (`pTrk`) `ID  `, `pnam`, `pArt`, `pDur`.
  - No `NSAppleScript`: the AppleScript runtime costs ~60 MB resident and is never loaded.
  - Events go out on a private serial queue (a slow Spotify never blocks the UI) and only while Spotify runs, so Spotify is never launched.
  - Play/pause updates the UI optimistically; the next notification confirms it.
- **Equalizer:** a `Canvas` driven by `TimelineView(.animation(minimumInterval: 1/12, paused: !isPlaying))`, with 4 sine-modulated bars and no audio capture.

### 5.2 Timer
- **Model:** `TimerItem { id, label, duration, endDate?, pausedRemaining?, finishedAt? }`.
- **State** is defined entirely by dates: running means `endDate != nil && finishedAt == nil`; paused means `pausedRemaining != nil`.
- **Scheduling, one job per timer (id = uuid):**
  - running: fire at `endDate` → `finish()`: mark finished, play `NSSound("Glass")`, peek 4 s;
  - finished: remove at `finishedAt + 120 s`;
  - paused: cancel.
- **Activity:** the newest finished timer is `.urgent` (with `expiresAt` = finishedAt+120 s and a tint). Otherwise the soonest-ending timer is `.normal`.
- **Relaunch:** timers whose end passed while the app was closed are marked finished silently.
- **Views:**
  - Countdown text uses `Text(timerInterval:countsDown:)`, so it ticks with no app timer.
  - The ring uses a 1 Hz `TimelineView`, only while visible.
  - A finished ring pulses (`phaseAnimator`), bounded by the 120 s linger.

### 5.3 Todo
- **Model:** `Todo { id, title, due?, done, createdAt }`, stored in `todos.json`. Completed items are purged on the next launch.
- **`QuickAddParser`:**
  1. `^(.*?)\s+in\s+(.+)$` where group 2 parses with `DurationParser`.
  2. Otherwise `NSDataDetector(.date)`. The matched range is removed from the title, along with dangling prepositions (at/on/by/in/for). A same-day time that has already passed rolls to tomorrow.
- **Scheduling per todo:** `soon-<id>` at `due − 15 min` (bumps `clock` so `activity` re-evaluates) and `due-<id>` at `due` (bumps `clock`, sets `justDue`, peeks for 4 s).
- **Activity:** the earliest todo that's overdue or due within 15 min. Overdue is `.urgent` and tinted red; soon is `.normal` and tinted blue.
- **Completing a todo:** strike-through plus a `success` checkmark, then removal 0.8 s later through a scheduled one-shot (no `asyncAfter` in plugins).
- **Keyboard:** the text field's focus calls `ctx.setWantsKeyboard`, which sets `store.editing`, so the island doesn't collapse while you type.

## 6. Sequences

**Timer finishes**
```
DispatchSource(wall) ─▶ OneShotScheduler.fireOne("timer.<uuid>") ─▶ TimerPlugin.finish
  ─▶ timers[i].finishedAt = now  (Observation) ─▶ registry.resolve → primary = timer(.urgent)
  ─▶ ctx.requestPeek(4) ─▶ AppDelegate.onPeek ─▶ each NotchController.peek ─▶ store.peekPluginID
  ─▶ NotchRootView: presentation .peek ─▶ onChange ─▶ controller grows window ─▶ spring open
  ─▶ 4 s later scheduler "host.peek.<display>" clears peek ─▶ .compact (red key line) ─▶ window shrinks after 0.5 s
```

**Mac sleeps through a todo's due time**
```
willSleep … didWake ─▶ AppDelegate.onWake ─▶ scheduler.rearm() fires "todo.due-<id>" ─▶ becameDue ─▶ peek
                                           ─▶ controllers.resetTransientState() (drops stale hover)
```

## 7. JSON on disk
```json
// timer/timers.json
[{ "id": "UUID", "label": "5m", "duration": 300, "endDate": "2026-11-01T18:05:00Z",
   "pausedRemaining": null, "finishedAt": null }]
// todo/todos.json
[{ "id": "UUID", "title": "call mom", "due": "2026-11-01T18:10:00Z", "done": false,
   "createdAt": "2026-11-01T18:00:00Z" }]
```

## 8. Build, test, ship
| Step | How |
|---|---|
| Build | `swift build` |
| Test | `scripts/test.sh`. It runs `swift test` and adds the Command Line Tools paths for swift-testing when Xcode isn't installed. Suites: Kit (arbiter, scheduler, duration parser, storage), plugins (timer maths and restore, quick-add parsing and ordering, Spotify payload), host (layout and geometry, presentation precedence, paging). |
| Ship | `scripts/bundle.sh`: release build → `build/DyaNotch.app` (Info.plist with `LSUIElement` and `NSAppleEventsUsageDescription`, entitlements `automation.apple-events`) → ad-hoc codesign with hardened runtime → `~/Applications` |
