import SwiftUI

/// Round icon button. `prominent` gives the white primary style (e.g. play/pause).
public struct NotchIconButton: View {
    private let symbol: String
    private let size: CGFloat
    private let prominent: Bool
    private let action: () -> Void
    @State private var hovering = false

    public init(_ symbol: String, size: CGFloat = 30, prominent: Bool = false, action: @escaping () -> Void) {
        self.symbol = symbol
        self.size = size
        self.prominent = prominent
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * (prominent ? 0.5 : 0.42), weight: .semibold))
                .foregroundStyle(prominent ? Color.black : DN.Palette.textPrimary)
                .frame(width: size, height: size)
                .background(Circle().fill(fill))
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle())
        .onHover { hovering = $0 }
    }

    private var fill: Color {
        if prominent { return .white }
        return hovering ? DN.Palette.controlFillHover : DN.Palette.controlFill
    }
}
