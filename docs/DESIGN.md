# DyaNotch: Design System

`Sources/DyaNotchKit/DesignTokens.swift` (`DN.*`) is the code mirror of this document. Change both together.

## 1. Principles
1. **It's the hardware.** On a notched screen the closed island is the notch itself: pure black, flush with the top edge, with flares melting into the menu bar. A user should not be able to see where the hardware ends and the app begins.
2. **Content hugs the camera.** Compact wings sit snug against the notch, equal width, showing *one* piece of information in one tint (Apple Live Activities guidance).
3. **Expanded is compact, bigger.** Elements move (`matchedGeometryEffect`) instead of disappearing and reappearing.
4. **Glanceable, not busy.** Show at most two things (primary wings plus a secondary badge). Show nothing when nothing is happening.
5. **Motion has a purpose.** Springs for shape, blur+fade for content, numeric transitions for digits. Nothing moves when the island is idle.

## 2. Anatomy
```
 menu bar ───────╮                                   ╭─────── menu bar
                 ╰╮  [wing]  ███ camera ███  [wing]  ╭╯        ← band (height = safe-area inset)
                  │      peek line / expanded page   │         ← content (margin 14)
                  ╰──────────────────────────────────╯         ← bottom radius
   top flare = concave curve into the menu bar      secondary badge ●  (28pt, 6pt gap)
```

## 3. States
```
CLOSED      ╰█████████╯                         notch + 4pt, flare 6, bottom 10. Invisible.
COMPACT  ╰[▣]█████████[▮▮▮]╯                   + 2 wings (h+4 ≈ 42pt each), flare 6, bottom 14
PEEK     ╰[▣]█████████[▮▮▮]─────╯               ≥380pt wide, +40pt, flare 10, bottom 18, ~2-4s
         │ Song title  Artist            │
         ╰───────────────────────────────╯
EXPANDED ╰ ♫ ⏲ ☑ ██████████████ ⚙ ╯              ≥560pt wide, +156pt, flare 19, bottom 24
         │ ┌────┐ Title                  │
         │ │art │ Artist                 │
         │ └────┘ ━━━━━━━━━○──── 1:02 -2:31│
         │        ⏮   ⏯   ⏭              │
         ╰────────────────────────────────╯
PILL (no notch): same sizes, floating 4pt under the menu bar, fully rounded, hidden when idle.
```

## 4. Tokens

### Colour
| Token | Value | Use |
|---|---|---|
| `notch` | `#000000` | Island fill. Never a material on notched screens |
| `surface` | `#1C1C1E` | Cards and input fields inside the island |
| `surfaceRaised` | `#2C2C2E` | Artwork placeholder |
| `textPrimary` / `Secondary` / `Tertiary` | white 100 / 62 / 38% | Text hierarchy |
| `spotify` | `#1DB954` | Fallback music tint |
| `timer` | `#FF9F0A` | Timer tint |
| `todo` | `#0A84FF` | Todo tint |
| `danger` | `#FF453A` | Overdue, timer done, invalid input |
| `success` | `#30D158` | Completed todo |
| Artwork tint | Average artwork colour, saturation ×1.2, brightness ≥ 0.75 | Equalizer, scrubber, glow |

**Key line:** while the primary activity is `.urgent`, a 1 pt outline in its tint at 55% traces the island. Apple tints the Dynamic Island's key line the same way.

### Shape
- **Radii:** compact artwork 5, artwork 12, card 12, button 10, tab 7. All corners use `.continuous` (squircle), matching what Alcove's site draws (`squircle.js`).
- **Concentric rule:** an inner radius equals the outer radius minus the margin. The expanded bottom radius is 24, and 24 − 14 ≈ 10–12 for cards.

### Spacing
`xs 4 · s 8 · m 12 · l 16`. Content margin 14. The wing width equals the band height + 4.

### Type (SF Pro, medium weight or heavier)
| Token | Spec | Use |
|---|---|---|
| `title` | 13 semibold | Peek line, todo text |
| `titleLarge` | 15 semibold | Track title |
| `body` / `bodyLarge` | 12 / 13 regular | Secondary lines |
| `caption` | 11 medium | Times, chips |
| `compactValue` | 13 semibold rounded, monospaced digits | Wing values |
| `digitsLarge` | 34 semibold rounded, monospaced digits | Timer cards |

Digits always use `.monospacedDigit()` plus `.contentTransition(.numericText())`.

### Icons
SF Symbols only, hierarchical rendering. 14 pt in the wings, 17 pt expanded, 13 pt for header tabs.

### Motion
| Token | Value | When |
|---|---|---|
| `open` | spring(response 0.42, damping 0.80) | → expanded, → peek |
| `close` | spring(response 0.45, damping 1.0) | → closed (no bounce, feels like hardware) |
| `swap` | spring(response 0.34, damping 0.88) | → compact, activity change, page change, list changes |
| `notchContent` transition | blur 8→0, opacity 0→1, scale 0.96→1 (top anchor) | All island content |
| Press | spring(0.2, 0.7), scale 0.92 | Buttons |

`accessibilityReduceMotion` turns every state change into easeInOut 0.2 s.

## 5. Plugin layouts
| Plugin | Compact leading | Compact trailing | Peek | Expanded |
|---|---|---|---|---|
| Spotify | 20 pt artwork, r5 | 4 equalizer bars in artwork tint, frozen when paused | Title (semibold) · artist (secondary) | 80 pt artwork with tinted glow; title/artist; scrubber with monospaced times; prev / **play** (38 pt, white) / next |
| Timer | Draining ring (orange; red and pulsing when done) | `12:04` countdown, or "Done" | Label + remaining | Horizontal cards (44 pt ring, 34 pt digits, pause/cancel or +1/dismiss), preset chips, custom field |
| Todo | ◌ (soon, blue) or ! (overdue, red) | "in 10m" / "8m late", `+N` for more | Title + due | Add field, list rows (circle → ✓, strike-through, slide out), due on the right, trash on hover |

## 6. Reference findings (REA, 2026-11-01)
Observed with REA against live pages through Chrome DevTools: `capture_web_screenshot` and `inspect_web_page`, plus the site's own static CSS/JS bundle. Used only as a sanity check; no assets or code were copied.

| Source | Observed | Our choice |
|---|---|---|
| tryalcove.com hero demo | Island ≈ 186 × 39 CSS px, near-black (`#0c0a09` family), lock glyph in the leading wing | Closed = hardware notch + 4 pt, pure black |
| tryalcove.com bundle | `squircle-*.js` module; `--ease-spring: cubic-bezier(.34, 1.2, .64, 1)` (overshooting ease) | `.continuous` corners everywhere; open spring with damping 0.8 gives similar overshoot |
| tryalcove.com palette | Warm site palette (`#fff0df`, `#441306`, `#d9b3ff`) | Marketing only; not relevant to the in-app look |
| dynamiclake.com hero | Dark page, floating rounded pill with app glyph (`#1C1C1C`-ish) | Pill style for screens without a notch |
| Atoll / boring.notch source (GitHub) | open 0.42/0.8, close 0.45/1.0, closed flare 6 / bottom 14, opened 19 / 24 | Adopted as tested defaults |
| DynamicNotchKit | `.bouncy(0.4)` open / `.smooth(0.4)` close, blur transitions | Blur+fade content transition |
| Apple HIG: Live Activities | Snug wings, balanced widths, one piece of information, 28 pt minimal circle, concentric margins, ≤ 2 s animations | Wing and secondary-badge rules above |
| Apple HIG: Materials | Liquid Glass is for controls, not content | No glass on the notch body |

## 7. UX complaints we design against
| Complaint (source) | Our countermeasure |
|---|---|
| Visualizer drains battery (boring.notch reports) | Fake bars, ≤ 12 fps, paused when not playing, torn down when not visible |
| Hover hangs or is stuck after sleep (NotchNook reviews) | Hover state reset on wake and on display change; 120 ms intent delay cancelled on exit |
| Covers fullscreen video (MacStories) | Hidden when the frontmost app is fullscreen on that screen |
| Fake notch looks wrong on external displays | Floating pill, hidden when idle |
| Clutter | Two activities at most; idle = invisible |
| Wings cover menu-bar icons | Wings ≈ band height; secondary badge only when a second activity exists |
| Breaks after macOS updates | Public APIs only; no SkyLight, MediaRemote or HUD interception |
| Steals keyboard focus | Non-activating panel; key only while expanded; focus handed back on collapse |
