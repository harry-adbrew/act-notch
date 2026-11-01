import Foundation

/// An activity tagged with the plugin that owns it.
public struct ActivityCandidate: Equatable, Sendable {
    public let pluginID: String
    public let activity: LiveActivity

    public init(pluginID: String, activity: LiveActivity) {
        self.pluginID = pluginID
        self.activity = activity
    }
}

/// Decides which activity owns the wings (primary) and which gets the small detached badge (secondary).
///
/// Order: drop expired → highest priority → most recent `since` → plugin id (deterministic tie-break).
public enum ActivityArbiter {
    public struct Resolution: Equatable, Sendable {
        public let primary: ActivityCandidate?
        public let secondary: ActivityCandidate?
    }

    public static func resolve(_ candidates: [ActivityCandidate], now: Date) -> Resolution {
        let ranked = candidates
            .filter { !$0.activity.isExpired(at: now) }
            .sorted(by: ranksHigher)
        return Resolution(primary: ranked.first, secondary: ranked.dropFirst().first)
    }

    private static func ranksHigher(_ a: ActivityCandidate, _ b: ActivityCandidate) -> Bool {
        if a.activity.priority != b.activity.priority { return a.activity.priority > b.activity.priority }
        if a.activity.since != b.activity.since { return a.activity.since > b.activity.since }
        return a.pluginID < b.pluginID
    }
}
