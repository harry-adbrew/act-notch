import DyaNotchKit
import SwiftUI

/// Expanded page: the running timers, then preset chips and a custom-duration field.
struct TimerPage: View {
    let plugin: TimerPlugin
    let namespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: DN.Space.m) {
            timers
            StartTimerBar(plugin: plugin)
        }
        .animation(DN.Motion.swap, value: plugin.timers)
    }

    @ViewBuilder
    private var timers: some View {
        if plugin.timers.isEmpty {
            Text("No timers running")
                .font(DN.Typography.bodyLarge)
                .foregroundStyle(DN.Palette.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 64)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DN.Space.m) {
                    ForEach(plugin.timers) { TimerCard(item: $0, plugin: plugin, namespace: namespace) }
                }
            }
            .scrollClipDisabled()
        }
    }
}

/// Preset chips (+1m, +5m, …) and a free-form field ("90s", "1h30m", "45").
private struct StartTimerBar: View {
    let plugin: TimerPlugin
    @State private var custom = ""
    @State private var invalid = false

    var body: some View {
        HStack(spacing: DN.Space.s) {
            ForEach(TimerPlugin.presets, id: \.self) { duration in
                NotchChip("+" + TimerPlugin.label(for: duration), tint: DN.Palette.timer) {
                    plugin.start(duration)
                }
            }
            TextField("Custom: 90s, 1h30m", text: $custom)
                .textFieldStyle(.plain)
                .font(DN.Typography.caption)
                .padding(.horizontal, 10)
                .frame(height: 24)
                .background(Capsule().fill(DN.Palette.controlFill))
                .overlay(Capsule().stroke(invalid ? DN.Palette.danger : .clear))
                .onSubmit(startCustom)
        }
    }

    private func startCustom() {
        guard let duration = DurationParser.parse(custom) else {
            invalid = true
            return
        }
        plugin.start(duration)
        custom = ""
        invalid = false
    }
}
