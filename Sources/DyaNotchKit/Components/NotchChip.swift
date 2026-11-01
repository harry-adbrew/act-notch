import SwiftUI

/// Small tinted capsule button, e.g. timer presets.
public struct NotchChip: View {
    private let title: String
    private let tint: Color
    private let action: () -> Void
    @State private var hovering = false

    public init(_ title: String, tint: Color, action: @escaping () -> Void) {
        self.title = title
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(DN.Typography.caption)
                .foregroundStyle(tint)
                .padding(.horizontal, 10)
                .frame(height: 24)
                .background(Capsule().fill(tint.opacity(hovering ? 0.24 : 0.14)))
                .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
        .onHover { hovering = $0 }
    }
}
