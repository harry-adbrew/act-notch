import DyaNotchKit
import SwiftUI

/// The whole island for one screen: one morphing black shape, the content for the current
/// presentation clipped inside it, and an optional secondary badge beside it.
struct NotchRootView: View {
    let store: NotchStore
    let registry: PluginRegistry
    let actions: NotchActions
    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let resolution = registry.resolve()
        let presentation = store.presentation(primary: resolution.primary)
        let secondary = presentation == .compact ? resolution.secondary : nil

        HStack(alignment: .top, spacing: NotchLayout.secondaryGap) {
            // Mirror the badge's width so the island stays centred on the camera.
            if secondary != nil {
                Color.clear.frame(width: NotchLayout.secondaryDiameter, height: 1)
            }

            island(presentation, primary: resolution.primary)

            if let secondary, let plugin = registry.plugin(secondary.pluginID) {
                SecondaryBadge(content: plugin.compactLeading(viewContext))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(animation(for: presentation), value: presentation)
        .animation(DN.Motion.swap, value: resolution.primary?.pluginID)
        .onChange(of: WindowKey(presentation: presentation, hasSecondary: secondary != nil), initial: true) { _, key in
            actions.presentationChanged(key.presentation, key.hasSecondary)
        }
    }

    // MARK: - Island

    private func island(_ presentation: Presentation, primary: ActivityCandidate?) -> some View {
        let layout = NotchLayout(geometry: store.geometry)
        let size = layout.shape(presentation)
        let radii = layout.radii(presentation)
        let shape = IslandShape.make(hasNotch: store.geometry.hasNotch, radii: radii)
        let urgentTint = primary?.activity.priority == .urgent ? primary?.activity.tint : nil

        return ZStack(alignment: .top) {
            shape
                .fill(DN.Palette.notch)
                .overlay {
                    // Key line: a tinted outline while something urgent wants attention.
                    if let urgentTint, presentation != .hidden {
                        shape.stroke(urgentTint.opacity(0.55), lineWidth: 1)
                    }
                }

            content(presentation, layout: layout, primary: primary)
                .padding(.horizontal, radii.top)
                .frame(width: size.width, height: size.height, alignment: .top)
                .clipShape(shape)
        }
        .frame(width: size.width, height: size.height)
        .opacity(presentation == .hidden && !store.geometry.hasNotch ? 0 : 1)
        .contentShape(shape)
        .onTapGesture {
            if presentation != .expanded { actions.expand() }
        }
    }

    @ViewBuilder
    private func content(_ presentation: Presentation, layout: NotchLayout, primary: ActivityCandidate?) -> some View {
        switch presentation {
        case .hidden, .closed:
            EmptyView()

        case .compact:
            if let primary, let plugin = registry.plugin(primary.pluginID) {
                CompactWings(plugin: plugin, layout: layout, context: viewContext)
                    .transition(.notchContent)
                    .id(primary.pluginID)
            }

        case .peek:
            if let id = store.peekPluginID, let plugin = registry.plugin(id) {
                PeekContent(plugin: plugin, layout: layout, context: viewContext)
                    .transition(.notchContent)
            }

        case .expanded:
            ExpandedView(
                store: store,
                registry: registry,
                layout: layout,
                namespace: namespace,
                primaryID: primary?.pluginID,
                openSettings: actions.openSettings
            )
            .transition(.notchContent)
        }
    }

    // MARK: - Helpers

    private var viewContext: NotchViewContext {
        NotchViewContext(namespace: namespace)
    }

    private func animation(for presentation: Presentation) -> Animation {
        if reduceMotion { return DN.Motion.reduced }
        switch presentation {
        case .expanded, .peek: return DN.Motion.open
        case .compact: return DN.Motion.swap
        case .closed, .hidden: return DN.Motion.close
        }
    }
}

/// Everything the window frame depends on.
private struct WindowKey: Equatable {
    let presentation: Presentation
    let hasSecondary: Bool
}
