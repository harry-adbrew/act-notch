import SwiftUI

/// The plugin contract.
///
/// Rules (see docs/LLD.md §2):
/// - Classes must be `@Observable`. The host reads `activity` and the view builders inside SwiftUI
///   bodies and relies on Observation to re-render.
/// - Never tick a property on a repeating timer. Derive live values in views from dates
///   (`TimelineView`, `Text(timerInterval:)`), and use `PluginContext.schedule` for one-shot thresholds.
/// - `init()` must be cheap. Subscribe and load in `activate`; release everything in `deactivate`.
/// - Views are built on demand and thrown away. Keep state in the plugin, not in the views.
@MainActor
public protocol NotchPlugin: AnyObject, Observable {
    static var manifest: PluginManifest { get }
    init()

    func activate(_ context: PluginContext) async throws
    func deactivate()

    /// `nil` means nothing to show in the compact state.
    var activity: LiveActivity? { get }

    /// Wing left of the camera. About 20pt, snug against the notch.
    func compactLeading(_ ctx: NotchViewContext) -> AnyView?
    /// Wing right of the camera. Same information as the leading wing, same tint.
    func compactTrailing(_ ctx: NotchViewContext) -> AnyView?
    /// One line shown under the notch during a peek.
    func peekView(_ ctx: NotchViewContext) -> AnyView?
    /// Page in the expanded pager. `nil` means the plugin has no page.
    func expandedView(_ ctx: NotchViewContext) -> AnyView?
}

public extension NotchPlugin {
    func deactivate() {}
    func compactLeading(_ ctx: NotchViewContext) -> AnyView? { nil }
    func compactTrailing(_ ctx: NotchViewContext) -> AnyView? { nil }
    func peekView(_ ctx: NotchViewContext) -> AnyView? { nil }
    func expandedView(_ ctx: NotchViewContext) -> AnyView? { nil }
}
