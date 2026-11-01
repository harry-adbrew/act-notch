import SwiftUI

/// A plugin's claim on the compact notch. The host shows at most two at once (see `ActivityArbiter`).
public struct LiveActivity: Equatable, Sendable {
    public enum Priority: Int, Comparable, Sendable {
        /// Background info, e.g. music playing.
        case ambient = 0
        /// Something the user started, e.g. a running timer.
        case normal = 1
        /// Needs attention now, e.g. a timer finished or a todo is due.
        case urgent = 2

        public static func < (a: Priority, b: Priority) -> Bool { a.rawValue < b.rawValue }
    }

    /// Stable within the plugin. A changed id is treated as a new activity.
    public var id: String
    public var priority: Priority
    /// Used for recency ordering among equal priorities.
    public var since: Date
    /// The arbiter drops the activity after this date, even if the plugin forgets to clear it.
    public var expiresAt: Date?
    /// Content tint, used for the key-line outline around the island.
    public var tint: Color?

    public init(id: String, priority: Priority, since: Date = .now, expiresAt: Date? = nil, tint: Color? = nil) {
        self.id = id
        self.priority = priority
        self.since = since
        self.expiresAt = expiresAt
        self.tint = tint
    }

    public func isExpired(at now: Date) -> Bool {
        expiresAt.map { $0 <= now } ?? false
    }
}
