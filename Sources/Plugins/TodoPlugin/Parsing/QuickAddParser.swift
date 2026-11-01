import DyaNotchKit
import Foundation

/// Turns "call mom in 10m" or "submit report at 5pm" into a title plus an optional due date.
///
/// 1. Relative: `<title> in <duration>`, where the duration is anything `DurationParser` accepts.
/// 2. Absolute: anything `NSDataDetector` recognises ("at 5pm", "tomorrow 9am", "on Friday").
///    A same-day time that has already passed rolls over to tomorrow.
/// 3. Otherwise the whole text is the title.
public enum QuickAddParser {
    public static func parse(_ raw: String, now: Date = .now, calendar: Calendar = .current) -> (title: String, due: Date?) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let relative = parseRelative(text, now: now) { return relative }
        if let absolute = parseAbsolute(text, now: now, calendar: calendar) { return absolute }
        return (text, nil)
    }

    private static func parseRelative(_ text: String, now: Date) -> (title: String, due: Date?)? {
        guard let match = text.firstMatch(of: /(?i)^(.*?)\s+in\s+(.+)$/),
              let seconds = DurationParser.parse(String(match.2)) else { return nil }
        return (clean(String(match.1)), now.addingTimeInterval(seconds))
    }

    private static func parseAbsolute(_ text: String, now: Date, calendar: Calendar) -> (title: String, due: Date?)? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue),
              let match = detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              var date = match.date,
              let range = Range(match.range, in: text) else { return nil }

        // "at 9am" typed after 9am means tomorrow, not a moment in the past.
        if date < now, calendar.isDate(date, inSameDayAs: now) {
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }

        var title = text
        title.removeSubrange(range)
        let cleaned = clean(title)
        return (cleaned.isEmpty ? text : cleaned, date)
    }

    /// Removes dangling prepositions left behind after stripping the date phrase.
    private static func clean(_ s: String) -> String {
        var text = s.trimmingCharacters(in: .whitespacesAndNewlines)
        while let match = text.firstMatch(of: /(?i)\s+(at|on|by|in|for)$/) {
            text.removeSubrange(match.range)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
    }
}
