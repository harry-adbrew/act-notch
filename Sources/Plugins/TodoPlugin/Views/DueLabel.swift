import DyaNotchKit
import SwiftUI

/// "in 10m", "5:30 PM", "8m late", with "+N" when more todos are waiting. Refreshes once a minute while visible.
struct DueLabel: View {
    let due: Date
    var additional: Int = 0
    let font: Font

    var body: some View {
        TimelineView(.everyMinute) { context in
            let remaining = due.timeIntervalSince(context.date)
            HStack(spacing: 4) {
                Text(Self.describe(remaining, due: due))
                    .foregroundStyle(remaining <= 0 ? DN.Palette.danger : DN.Palette.todo)
                if additional > 0 {
                    Text("+\(additional)")
                        .foregroundStyle(DN.Palette.textTertiary)
                }
            }
            .font(font)
            .monospacedDigit()
            .lineLimit(1)
        }
    }

    static func describe(_ remaining: TimeInterval, due: Date) -> String {
        let minutes = Int((abs(remaining) / 60).rounded())
        switch remaining {
        case ...(-60):
            return minutes < 60 ? "\(minutes)m late" : "\(minutes / 60)h late"
        case ..<60:
            return "now"
        case ..<3600:
            return "in \(minutes)m"
        default:
            return Calendar.current.isDateInToday(due)
                ? due.formatted(date: .omitted, time: .shortened)
                : due.formatted(.dateTime.weekday(.abbreviated).hour().minute())
        }
    }
}
