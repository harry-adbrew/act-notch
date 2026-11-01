import DyaNotchKit
import SwiftUI

/// Ring that drains as the timer runs. Turns red and pulses when finished.
/// Refreshes once a second, and only while it is on screen.
struct TimerRing: View {
    let item: TimerItem
    var size: CGFloat = 16
    var lineWidth: CGFloat = 2.5

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            NotchRing(
                fraction: item.isFinished ? 1 : item.fraction(at: context.date),
                tint: item.isFinished ? DN.Palette.danger : DN.Palette.timer,
                lineWidth: lineWidth
            )
        }
        .frame(width: size, height: size)
        .modifier(Pulse(active: item.isFinished))
    }
}

/// Gentle scale pulse while `active`. Bounded in practice by the finished-timer linger time.
private struct Pulse: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.phaseAnimator([1.0, 1.25]) { view, scale in
                view.scaleEffect(scale)
            } animation: { _ in
                .easeInOut(duration: 0.6)
            }
        } else {
            content
        }
    }
}
