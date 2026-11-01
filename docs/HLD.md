# DyaNotch: High-Level Design

## 1. Shape of the system
One process, one SwiftPM package, zero third-party dependencies.

```
                ┌────────────────────────── DyaNotch (host app, LSUIElement) ──────────────────────────┐
 NSWorkspace ──▶│ ScreenObserver ──▶ NotchController (one per screen)                                   │
 screen/sleep   │                       │  owns NotchPanel (NSPanel)  ◀── grows/shrinks on state change  │
 notifications  │                       │  owns NotchStore (@Observable: mode, hover, page, peek)        │
                │                       ▼                                                                │
                │                 NotchRootView (SwiftUI) ── reads ──▶ PluginRegistry ── ActivityArbiter │
                │                                                       │  (shared by every screen)       │
                │                                                       ▼                                │
                │                         ┌───────────── DyaNotchKit (SDK) ─────────────┐                │
                │                         │ NotchPlugin · PluginContext · LiveActivity   │                │
                │                         │ OneShotScheduler · PluginStorage · Tokens    │                │
                │                         └──────────────▲──────────────────────────────┘                │
                │             SpotifyPlugin       TodoPlugin        TimerPlugin   (depend on Kit only)   │
                └──────────────────┬─────────────────┬────────────────┬──────────────────────────────────┘
   Spotify distributed notif. ─────┘   JSON files in Application Support      one-shot wall-clock timers
   + Apple Events (commands)
```

### Components
| Component | Responsibility |
|---|---|
| **DyaNotchKit** | The public plugin contract plus shared runtime pieces (scheduler, storage, arbiter, design tokens, duration parser). It's the only module a plugin may import besides Apple frameworks. |
| **PluginRegistry** | Knows the plugin types, the enabled set (UserDefaults), and live instances. Activates plugins lazily and disables any that throw. Exposes the resolved primary/secondary activity. |
| **NotchController** | One per displayed screen. Places the panel from `NotchGeometry` and resizes it on presentation changes (grow first, shrink after the close animation). Handles hover, click-outside, scroll paging and key-window hand-back. |
| **NotchStore** | The only UI state root (`@Observable`): `mode`, `peek`, `selectedPage`, `isSuspended`. There are no other singletons. |
| **NotchRootView** | Maps (store × arbiter) to a `Presentation` (closed/compact/peek/expanded/hidden) and draws one morphing `NotchShape` plus plugin content. |
| **ScreenObserver** | Display configuration changes, sleep/wake, screen sleep, lock, Space changes (fullscreen detection). Pure notifications, no polling. |

## 2. Presentation state machine
```
            activity appears                hover ≥120ms / click
  CLOSED ─────────────────────▶ COMPACT ─────────────────────────▶ EXPANDED
    ▲  ◀───── activity gone ────── │  ▲                                  │
    │                              │  └──── pointer left 300ms / ────────┘
    │                    peek req. ▼        click outside / Esc
    │                            PEEK ── 2s or hover ──▶ (COMPACT | EXPANDED)
    └─ (any) ── lock / screens sleep / fullscreen app ──▶ HIDDEN ── wake/unlock ──▶ previous
```
- `Presentation` is derived and never stored. `mode` (closed/expanded) plus `peekUntil` live in the store. "Compact" means `mode == .closed` with a primary activity.
- On a screen without a notch, closed with no activity is `hidden` (nothing drawn). There is still a hover strip at the top centre.

## 3. Event sources (all push, no polling)
| Source | Mechanism | Consumer |
|---|---|---|
| Spotify state | `DistributedNotificationCenter` `com.spotify.client.PlaybackStateChanged` | SpotifyPlugin |
| Spotify launch/quit | `NSWorkspace.didLaunch/didTerminateApplication` | SpotifyPlugin |
| Due times / timer ends | `OneShotScheduler`: one wall-clock `DispatchSourceTimer` per job, re-checked on wake | Todo, Timer |
| Displays | `NSApplication.didChangeScreenParametersNotification` | ScreenObserver → controllers |
| Sleep/wake, screens sleep | `NSWorkspace` notifications | ScreenObserver (suspend, reset hover, re-arm scheduler) |
| Lock/unlock | Distributed `com.apple.screenIsLocked/Unlocked` | ScreenObserver |
| Fullscreen apps | `NSWorkspace.activeSpaceDidChangeNotification` → one `CGWindowListCopyWindowInfo` check | ScreenObserver |
| Hover | `NSTrackingArea(.activeAlways, .mouseEnteredAndExited, .inVisibleRect)` on the panel's content view | NotchController |
| Click outside | Global `leftMouseDown` monitor, **installed only while expanded** | NotchController |
| Paging swipe | Local `scrollWheel` monitor, **installed only while expanded** | NotchController |

Things that animate (equalizer, progress, ring) are `TimelineView`s inside views that exist only while visible. `Text(timerInterval:)` counts down without any app timer.

## 4. Plugin model
- **In-process.** Every plugin is a `@MainActor`, `Observable` class conforming to `NotchPlugin`. The host reads `plugin.activity` inside SwiftUI bodies, so Observation re-renders exactly when a plugin publishes a change. There is no Combine and no notifications.
- **Lifecycle:** `init()` (must be cheap) → `activate(ctx)` (subscribe, load state) → `deactivate()` (release everything). Disabled plugins are never instantiated.
- **Capabilities** through `PluginContext`:
  - namespaced storage
  - one-shot scheduling
  - `requestPeek`
  - `setWantsKeyboard`
  - an `os.Logger`

  Plugins never touch windows, screens or other plugins.
- **Failure isolation:** if `activate` throws, the registry disables the plugin and logs the error. A crash inside a plugin still takes the process down. That's accepted for first-party code; untrusted third-party code would need the Phase-2 XPC host, which is explicitly deferred.
- **Phase 2 (v0.4):** load `~/Library/Application Support/DyaNotch/Plugins/*.bundle` whose `NSPrincipalClass` subclasses an `@objc` base class bridging to `NotchPlugin`. Swift has no stable ABI for protocol conformances across separately compiled bundles, so the bridge is required.

## 5. Threading
- All UI, plugin and store state is `@MainActor`.
- Off-main work: storage writes (a serial utility queue, coalesced 300 ms), artwork download (`URLSession`), Apple Events to Spotify (a dedicated serial queue).
- Results hop back with `await MainActor.run` or `Task { @MainActor in }`.
- Swift 6 strict concurrency is on.

## 6. Persistence
| Data | Where |
|---|---|
| Plugin data | `~/Library/Application Support/DyaNotch/<plugin-id>/*.json`, written atomically and coalesced; flushed on quit |
| Settings | `UserDefaults` (`dn.*` keys) |

There are no databases and no caches on disk. The artwork cache is an in-memory 20-entry LRU.

## 7. Window strategy (why it's seamless)
- `NSPanel`, `[.borderless, .nonactivatingPanel]`, level `.statusBar + 1`, `[.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]`, clear and non-opaque, no shadow, `sharingType = .none` (optional).
- It is pinned to `screen.frame.maxY` and centred on the notch, so the anti-aliased top edge is off-screen and the black fill merges with the hardware.
- **The window frame changes only on presentation transitions, never per frame.** It grows *before* an opening animation and shrinks *after* a closing one. Everything outside the window passes clicks straight to the menu bar. Inside, `hitTest` returns nil outside the shape.
- `canBecomeKey` is true only while expanded, so text fields work. On collapse, key status goes back to the previously frontmost app.

## 8. Security and privacy
- **Network:** only `https://open.spotify.com/oembed` and the returned `i.scdn.co` image.
- **Data:** no telemetry. Todo data stays local.
- **APIs:** no private APIs. Apple Events go only to `com.spotify.client`, and only while it's running.

## 9. Budgets and how they are enforced
| Budget | Enforced by |
|---|---|
| Idle CPU ≈ 0 | No repeating timers anywhere. Code review rule: `Timer.scheduledTimer(repeats: true)` and `Task.sleep` loops are banned (grep in CI). |
| RSS < 40 MB | One `NSHostingView` per screen; plugin views are built only when presented; artwork kept at 160 px. |
| Size < 5 MB | No dependencies; no bundled assets beyond SF Symbols. |

## 10. Deliberately excluded (and why)
| Excluded | Why |
|---|---|
| Private CGS/SkyLight spaces | Public panel behaviours already stay above fullscreen apps |
| HUD replacement | Needs an event tap and Accessibility permission; a bug leaves the media keys dead |
| MediaRemote and the perl adapter | Commands are blocked on 26.x; costs a child process |
| Global mouse-move monitors, 60 Hz timers, FFT visualizers, Lottie | Constant CPU drain or an extra dependency |
