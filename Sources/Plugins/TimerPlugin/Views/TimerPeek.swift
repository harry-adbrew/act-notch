import DyaNotchKit
import SwiftUI

/// One-line peek: "<label> timer finished" or the running label, with the remaining time.
struct TimerPeek: View {
    let item: TimerItem

    var body: some View {
        HStack(spacing: DN.Space.s) {
            Image(systemName: item.isFinished ? "bell.fill" : "timer")
                .foregroundStyle(item.isFinished ? DN.Palette.danger : DN.Palette.timer)
            Text(item.isFinished ? "\(item.label) timer finished" : item.label)
                .font(DN.Typography.title)
                .foregroundStyle(DN.Palette.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
            TimerRemainingText(item: item, font: DN.Typography.digits)
        }
    }
}
