import Foundation

/// Parses human durations: "90s", "10m", "1h30m", "1h 30 min", "2 hours", "1:30" (m:ss), "25" (minutes).
public enum DurationParser {
    public static func parse(_ input: String) -> TimeInterval? {
        let s = input.trimmingCharacters(in: .whitespaces).lowercased()
        guard !s.isEmpty else { return nil }

        if let minutes = Double(s) { return minutes > 0 ? minutes * 60 : nil }

        // h:mm:ss or m:ss
        let colon = s.split(separator: ":")
        if (2...3).contains(colon.count) {
            let parts = colon.compactMap { Double($0) }
            guard parts.count == colon.count else { return nil }
            let total = parts.reduce(0) { $0 * 60 + $1 }
            return total > 0 ? total : nil
        }

        let pattern = /(\d+(?:\.\d+)?)\s*(hours|hour|hrs|hr|h|minutes|minute|mins|min|m|seconds|second|secs|sec|s)(?![a-z])/
        var total: TimeInterval = 0
        var consumed = s
        for match in s.matches(of: pattern) {
            guard let value = Double(match.1) else { return nil }
            switch match.2.first {
            case "h": total += value * 3600
            case "m": total += value * 60
            default: total += value
            }
            consumed = consumed.replacingOccurrences(of: String(match.0), with: "")
        }
        // Reject input with leftovers we did not understand ("10 bananas").
        guard total > 0, consumed.trimmingCharacters(in: .whitespaces.union(.punctuationCharacters)).isEmpty else { return nil }
        return total
    }

    /// "1:05:09", "4:05", "0:09" style for compact displays.
    public static func clock(_ interval: TimeInterval) -> String {
        let t = max(0, Int(interval.rounded(.up)))
        let h = t / 3600, m = (t % 3600) / 60, s = t % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
