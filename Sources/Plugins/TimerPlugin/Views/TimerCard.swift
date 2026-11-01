import DyaNotchKit
import SwiftUI

/// One timer in the expanded page: big ring, big digits, and its two controls.
struct TimerCard: View {
    let item: TimerItem
    let plugin: TimerPlugin
    let namespace: Namespace.ID

    var body: some View {
        HStack(spacing: DN.Space.m) {
            TimerRing(item: item, size: 44, lineWidth: 4)
                .matchedGeometryEffect(id: TimerPlugin.ringID(item.id), in: namespace)

            VStack(alignment: .leading, spacing: 2) {
                TimerRemainingText(item: item, font: DN.Typography.digitsLarge)
                Text(item.label)
                    .font(DN.Typography.caption)
                    .foregroundStyle(DN.Palette.textSecondary)
            }

            Spacer(minLength: DN.Space.s)

            controls
        }
        .padding(DN.Space.m)
        .frame(width: 250)
        .background(RoundedRectangle(cornerRadius: DN.Radius.card, style: .continuous).fill(DN.Palette.surface))
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    /// Finished: +1 min / dismiss. Running or paused: pause-resume / cancel.
    private var controls: some View {
        VStack(spacing: DN.Space.s) {
            if item.isFinished {
                NotchIconButton("plus", size: 28) { plugin.extend(item.id) }
            } else {
                NotchIconButton(item.isPaused ? "play.fill" : "pause.fill", size: 28) { plugin.togglePause(item.id) }
            }
            NotchIconButton("xmark", size: 28) { plugin.remove(item.id) }
        }
    }
}
