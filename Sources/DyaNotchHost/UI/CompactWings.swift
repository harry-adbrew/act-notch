import DyaNotchKit
import SwiftUI

/// Leading and trailing wings hugging the camera, with the notch body as a gap in between.
struct CompactWings: View {
    let plugin: any NotchPlugin
    let layout: NotchLayout
    let context: NotchViewContext

    var body: some View {
        HStack(spacing: 0) {
            wing(plugin.compactLeading(context))
            Spacer(minLength: layout.geometry.notchSize.width)
            wing(plugin.compactTrailing(context))
        }
        .frame(height: layout.bandHeight)
        // Wing text shrinks rather than overflowing (e.g. "1:02:05").
        .minimumScaleFactor(0.6)
        .lineLimit(1)
    }

    private func wing(_ content: AnyView?) -> some View {
        (content ?? AnyView(EmptyView()))
            .frame(width: layout.wing, height: layout.bandHeight)
    }
}
