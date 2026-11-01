import SwiftUI

/// Shrinks slightly while pressed. The standard button style inside the island.
public struct PressableStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(DN.Motion.press, value: configuration.isPressed)
    }
}
