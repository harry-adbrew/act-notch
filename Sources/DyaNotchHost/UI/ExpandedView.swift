import DyaNotchKit
import SwiftUI

/// Header in the camera band (tabs left of the camera, settings right), the current plugin page below.
///
/// Page choice: the user's pick, else the plugin owning the primary activity, else the first page.
struct ExpandedView: View {
    let store: NotchStore
    let registry: PluginRegistry
    let layout: NotchLayout
    let namespace: Namespace.ID
    let primaryID: String?
    let openSettings: () -> Void

    var body: some View {
        let pages = registry.active.filter { $0.plugin.expandedView(context) != nil }
        let current = currentPage(in: pages)

        VStack(spacing: 0) {
            ExpandedHeader(
                pages: pages.map(\.manifest),
                currentID: current?.manifest.id,
                cameraGap: layout.geometry.notchSize.width,
                select: { store.selectedPage = $0 },
                openSettings: openSettings
            )
            .frame(height: layout.bandHeight)

            page(current)
                .padding(.horizontal, DN.Space.margin)
                .padding(.top, DN.Space.s)
                .padding(.bottom, DN.Space.margin)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .animation(DN.Motion.swap, value: current?.manifest.id)
        }
        .onChange(of: PageState(ids: pages.map(\.manifest.id), current: current?.manifest.id), initial: true) { _, state in
            // Tell the store so swipe paging knows the order.
            store.pageIDs = state.ids
            store.currentPage = state.current
        }
    }

    private var context: NotchViewContext {
        NotchViewContext(namespace: namespace)
    }

    private func currentPage(in pages: [PluginRegistry.Entry]) -> PluginRegistry.Entry? {
        func page(_ id: String?) -> PluginRegistry.Entry? {
            id.flatMap { id in pages.first { $0.manifest.id == id } }
        }
        return page(store.selectedPage) ?? page(primaryID) ?? pages.first
    }

    @ViewBuilder
    private func page(_ entry: PluginRegistry.Entry?) -> some View {
        if let entry {
            entry.plugin.expandedView(context)
                .id(entry.manifest.id)
                .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 6)), removal: .opacity))
        } else {
            Text("No plugins enabled")
                .font(DN.Typography.body)
                .foregroundStyle(DN.Palette.textSecondary)
        }
    }
}

private struct PageState: Equatable {
    let ids: [String]
    let current: String?
}
