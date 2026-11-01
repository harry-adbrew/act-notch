import DyaNotchKit
import SwiftUI

/// The band level with the camera: plugin tabs on the left, settings on the right, nothing behind the camera.
struct ExpandedHeader: View {
    let pages: [PluginManifest]
    let currentID: String?
    /// Width to keep clear for the camera housing.
    let cameraGap: CGFloat
    let select: (String) -> Void
    let openSettings: () -> Void

    var body: some View {
        HStack(spacing: DN.Space.xs) {
            ForEach(pages) { page in
                TabButton(symbol: page.symbol, selected: page.id == currentID) { select(page.id) }
            }
            Spacer(minLength: cameraGap)
            TabButton(symbol: "gearshape", selected: false, action: openSettings)
        }
        .padding(.horizontal, DN.Space.margin)
    }
}

private struct TabButton: View {
    let symbol: String
    let selected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: DN.Icon.tab, weight: .semibold))
                .foregroundStyle(selected ? DN.Palette.textPrimary : DN.Palette.textTertiary)
                .frame(width: 26, height: 22)
                .background(RoundedRectangle(cornerRadius: DN.Radius.tab, style: .continuous).fill(fill))
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .onHover { hovering = $0 }
    }

    private var fill: Color {
        if selected { return DN.Palette.controlFillSelected }
        return hovering ? Color.white.opacity(0.07) : .clear
    }
}
