# DyaNotch: Product Requirements

**Status:** v0.1 draft · **Owner:** Hari Om Bhardwaj · **Last updated:** 2026-11-01

## 1. Problem
On notched MacBooks, the notch is dead space in the middle of the menu bar. iPhone's Dynamic Island showed that this space can carry glanceable, live information. Existing Mac apps fall into two groups:
- **Heavy, feature-sprawling clones.** Atoll, built on boring.notch, keeps a perl child process running and has about 16 observed singletons, many polling loops and Lottie. Reviewers report extra battery drain and hover "hangs" after the Mac sleeps.
- **Polished closed apps.** Alcove ($12.99) and DynamicLake are not extensible (DynamicLake has an SDK, but it's tied to their marketplace) and add features the user doesn't want.

**DyaNotch** is the opposite trade-off. It does a few things, does them seamlessly, and costs nothing at idle. A small plugin SDK means new capabilities never bloat the core.

## 2. Target user
A single power user (the author) on a notched Apple Silicon MacBook running macOS 14 or later (developed on 26.5), sometimes connected to an external display. They live in Spotify and want timers and quick todos without switching apps.

## 3. Goals
| # | Goal | Measured by |
|---|------|-------------|
| G1 | Feels like part of the hardware | Black shape matches the hardware notch exactly; no focus stealing; springs, no jank |
| G2 | Lightest possible | Idle CPU ≈ 0%, RSS < 40 MB, `.app` < 5 MB, **zero** third-party dependencies |
| G3 | Extensible | Plugins only see `DyaNotchKit`; a new plugin is under 200 LOC and touches no host code beyond one registry line |
| G4 | Useful on day one | Spotify, Todo and Timer plugins working end to end |

## 4. Non-goals (v1)
Replacing the system volume/brightness HUD, clipboard history, file shelf/AirDrop, system-wide "Now Playing" via MediaRemote, calendar, weather, lock-screen widgets, an update framework (Sparkle), Mac App Store distribution, and syncing todos.

## 5. Core experience
| State | When | What the user sees |
|---|---|---|
| **Closed** | Nothing active | Invisible: the black shape exactly covers the hardware notch |
| **Compact** | A plugin has a live activity | Two small "wings" grow out of the notch: leading glyph or art, trailing value |
| **Peek** | A system event (track change, timer done, todo due) | Auto-expands briefly (about 2 s) with a one-line summary, then returns to compact |
| **Expanded** | Pointer hovers for 120 ms, or a click | A full panel with a page per plugin (tabs in the header, swipe to switch). Collapses 300 ms after the pointer leaves, or on a click outside |

External displays (no notch) get a floating pill under the menu bar instead of a fake notch. It is hidden when nothing is active.

## 6. Plugins: user stories and acceptance criteria

### 6.1 Spotify (auto-detected)
- **S1** As a listener, when I play music in Spotify, I see the album art and a moving equalizer beside the notch without configuring anything.
  - AC: within 1 s of playback starting, compact shows the art and bars; the bars freeze when paused; quitting Spotify removes the activity.
- **S2** When the track changes, the notch peeks the new title and artist.
  - AC: peek lasts about 2 s; artwork updates; no peek when only the play/pause state changed.
- **S3** In expanded view I can play/pause, skip, go back, and scrub.
  - AC: controls work after a one-time macOS Automation prompt; the scrubber shows elapsed and remaining time and seeks on release.
- **S4** The app never launches Spotify by itself and never polls.

### 6.2 Todo / reminders (local)
- **T1** I can type "call mom in 10m" or "submit report at 5pm" and get a todo with a due time.
  - AC: the parser handles `in <n>(s|m|h)`, `at <time>`, and natural dates via `NSDataDetector`; the due phrase is stripped from the title.
- **T2** When a todo is due, the notch peeks it. While it's overdue or due within 15 min, compact shows it.
  - AC: fires on time even if the Mac slept through the due time (it fires on wake); survives relaunch.
- **T3** I can complete (click the circle) or delete a todo in the expanded list.
  - AC: completed rows strike through and slide out; data lives in `~/Library/Application Support/DyaNotch/todo/todos.json`.

### 6.3 Timers
- **M1** I can start a timer from presets (1/5/10/25 min) or a custom value ("90s", "1h30m", "45").
- **M2** Compact shows a progress ring and the remaining time, ticking without jitter.
- **M3** Several timers can run at once; I can pause, resume and cancel.
- **M4** When a timer ends: a sound, an urgent peek, and "+1 min" and "Dismiss" buttons.
  - AC: based on end dates, so no drift; still correct after sleep and relaunch.

## 7. Settings
- Enable/disable each plugin (a disabled plugin is never instantiated)
- Launch at login
- Expand on hover vs. click only
- Hide in fullscreen apps
- Hide from screen sharing/screenshots
- Display: notched/main screen only, or all screens
- Quit

Reached via the gear icon in the expanded header or by right-clicking the notch. There's no Dock icon and no menu-bar item.

## 8. Permissions
| Permission | Why | When asked |
|---|---|---|
| Automation → Spotify | Controls and the initial now-playing state | First time Spotify is detected |
| Network | Spotify artwork via the public oEmbed endpoint | n/a (outgoing HTTPS only) |

No Accessibility, Screen Recording, Calendar or Bluetooth permissions.

## 9. Performance budgets (release gate)
- Idle (nothing playing) CPU ≈ 0.0% over 5 minutes; no periodic wakeups in `log stream`.
- Spotify playing, notch compact: < 2% CPU on an M-series Mac (equalizer at ≤ 12 fps, only while visible).
- RSS < 40 MB idle. `.app` < 5 MB. Cold start < 300 ms to first frame.

## 10. Risks
| Risk | Mitigation |
|---|---|
| Spotify changes its distributed-notification payload | Parser tolerates missing keys; one Apple Events read of the current state at startup |
| `sharingType = .none` is ignored by ScreenCaptureKit on newer macOS | Shipped as best effort; "hide titles while sharing" is a later item |
| Wings cover status-bar items in a crowded menu bar | Wings are kept to about the notch height (≈ 38 pt) |
| In-process plugins can crash the host | Only first-party plugins in v1; Phase 2 adds `.bundle` loading behind an opt-in |

## 11. Milestones
| Version | Scope |
|---|---|
| v0.1 | Shell (window, geometry, states, hover, settings) + Timer plugin |
| v0.2 | Spotify plugin |
| v0.3 | Todo plugin |
| v0.4 | SDK docs, `.bundle` plugin loading, URL scheme/App Intents, swipe gestures, global hotkey, battery plugin |
