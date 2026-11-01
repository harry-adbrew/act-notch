import DyaNotchKit
import SwiftUI

/// The island surfaces for timers: ring | remaining time in compact, a summary line in peek,
/// cards plus presets in expanded.
extension TimerPlugin {
    public func compactLeading(_ ctx: NotchViewContext) -> AnyView? {
        guard let item = featured else { return nil }
        return AnyView(
            TimerRing(item: item)
                .matchedGeometryEffect(id: Self.ringID(item.id), in: ctx.namespace)
        )
    }

    public func compactTrailing(_ ctx: NotchViewContext) -> AnyView? {
        guard let item = featured else { return nil }
        return AnyView(TimerRemainingText(item: item, font: DN.Typography.compactValue))
    }

    public func peekView(_ ctx: NotchViewContext) -> AnyView? {
        guard let item = featured else { return nil }
        return AnyView(TimerPeek(item: item))
    }

    public func expandedView(_ ctx: NotchViewContext) -> AnyView? {
        AnyView(TimerPage(plugin: self, namespace: ctx.namespace))
    }
}
