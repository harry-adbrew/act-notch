import DyaNotchKit
import SwiftUI

/// Detached black circle beside the island showing a second activity's glyph
/// (Apple's "minimal" presentation).
struct SecondaryBadge: View {
    let content: AnyView?

    var body: some View {
        Circle()
            .fill(DN.Palette.notch)
            .frame(width: NotchLayout.secondaryDiameter, height: NotchLayout.secondaryDiameter)
            .overlay { content?.scaleEffect(0.8) }
            .padding(.top, 2)
    }
}
