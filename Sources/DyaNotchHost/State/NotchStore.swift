import DyaNotchKit
import Foundation
import Observation

/// The single UI-state root for one screen. Everything else is derived from it.
@MainActor
@Observable
final class NotchStore {
    enum Mode { case closed, expanded }

    var mode: Mode = .closed
    /// Plugin currently peeking, if any.
    var peekPluginID: String?
    /// Page chosen by the user in the expanded state. `nil` = follow the primary activity.
    var selectedPage: String?
    /// Lock screen, screens asleep or a fullscreen app: draw nothing.
    var suspended = false
    /// True while a plugin text field has focus; stops the island collapsing when the pointer leaves.
    var editing = false
    var geometry: NotchGeometry

    /// Reported by the expanded view so swipe paging knows the page order. Not observed.
    @ObservationIgnored var pageIDs: [String] = []
    @ObservationIgnored var currentPage: String?

    init(geometry: NotchGeometry) {
        self.geometry = geometry
    }

    func presentation(primary: ActivityCandidate?) -> Presentation {
        if suspended { return .hidden }
        if mode == .expanded { return .expanded }
        if peekPluginID != nil { return .peek }
        if primary != nil { return .compact }
        return geometry.hasNotch ? .closed : .hidden
    }

    /// Moves `delta` pages from the current one, wrapping around.
    func turnPage(by delta: Int) {
        guard !pageIDs.isEmpty else { return }
        let current = currentPage.flatMap(pageIDs.firstIndex(of:)) ?? 0
        let count = pageIDs.count
        selectedPage = pageIDs[((current + delta) % count + count) % count]
    }
}
