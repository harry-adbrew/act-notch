import SwiftUI

public extension AnyTransition {
    /// Island content enters and leaves with blur, fade and a slight scale from the top,
    /// rather than opacity alone.
    static var notchContent: AnyTransition {
        .modifier(
            active: BlurFade(blur: 8, opacity: 0, scale: 0.96),
            identity: BlurFade(blur: 0, opacity: 1, scale: 1)
        )
    }
}

private struct BlurFade: ViewModifier {
    let blur: CGFloat
    let opacity: Double
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .opacity(opacity)
            .scaleEffect(scale, anchor: .top)
    }
}
