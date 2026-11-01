import DyaNotchKit
import SwiftUI

/// Remaining time. Running timers count down with `Text(timerInterval:)`, so no app timer is involved.
struct TimerRemainingText: View {
    let item: TimerItem
    let font: Font

    var body: some View {
        label
            .font(font)
            .monospacedDigit()
            .contentTransition(.numericText(countsDown: true))
            .lineLimit(1)
    }

    @ViewBuilder
    private var label: some View {
        if item.isFinished {
            Text("Done")
                .foregroundStyle(DN.Palette.danger)
        } else if let end = item.endDate, end > .now {
            Text(timerInterval: Date.now...end, countsDown: true, showsHours: true)
                .foregroundStyle(DN.Palette.timer)
        } else {
            // Paused.
            Text(DurationParser.clock(item.remaining(at: .now)))
                .foregroundStyle(DN.Palette.textSecondary)
        }
    }
}
