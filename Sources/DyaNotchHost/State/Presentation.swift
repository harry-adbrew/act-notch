/// What the island is showing. Derived on every render from `NotchStore` + the primary activity;
/// never stored.
///
/// ```
/// hidden    nothing drawn (locked, screens asleep, fullscreen app, idle pill screen)
/// closed    black shape exactly over the hardware notch
/// compact   wings either side of the notch (a plugin has a live activity)
/// peek      compact + one summary line, for a few seconds after an event
/// expanded  header tabs + a plugin page
/// ```
enum Presentation: Equatable {
    case hidden, closed, compact, peek, expanded
}
