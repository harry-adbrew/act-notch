import DyaNotchKit
import SwiftUI

/// The wings plus the plugin's one-line summary underneath.
struct PeekContent: View {
    let plugin: any NotchPlugin
    let layout: NotchLayout
    let context: NotchViewContext

    var body: some View {
        VStack(spacing: 0) {
            CompactWings(plugin: plugin, layout: layout, context: context)
            plugin.peekView(context)
                .padding(.horizontal, DN.Space.margin)
                .frame(height: NotchLayout.peekContentHeight - 6)
        }
    }
}
