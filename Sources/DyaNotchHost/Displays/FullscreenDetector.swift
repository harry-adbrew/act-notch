import AppKit

/// Detects a fullscreen app or video on a screen, so the island can get out of the way.
///
/// One `CGWindowListCopyWindowInfo` call per Space or app change. Reading window *bounds* needs no
/// Screen Recording permission (only names and contents do).
enum FullscreenDetector {
    /// True when the frontmost app has a normal-layer window covering the whole of `screen`.
    @MainActor
    static func hasFullscreenApp(on screen: NSScreen) -> Bool {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]] else { return false }

        let target = quartzRect(for: screen)
        return windows.contains { info in
            guard (info[kCGWindowOwnerPID as String] as? pid_t) == pid,
                  (info[kCGWindowLayer as String] as? Int) == 0,
                  let boundsDict = info[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDict) else { return false }
            return bounds.equalTo(target)
        }
    }

    /// Converts a screen frame (bottom-left origin) to Quartz window coordinates
    /// (top-left origin, relative to the primary display).
    @MainActor
    private static func quartzRect(for screen: NSScreen) -> CGRect {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? screen.frame.height
        return CGRect(
            x: screen.frame.minX,
            y: primaryHeight - screen.frame.maxY,
            width: screen.frame.width,
            height: screen.frame.height
        )
    }
}
