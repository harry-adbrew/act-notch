import AppKit
import DyaNotchKit
import SwiftUI

/// One per displayed screen. Owns the panel and the store, and turns input and system events into
/// state changes. The mechanics live in small helpers:
/// `WindowFramer` (frame), `HoverIntent` (hover timing), `ExpandedInputMonitor` (click-outside / Esc / swipe).
@MainActor
final class NotchController {
    let store: NotchStore

    private let registry: PluginRegistry
    private let settings: AppSettings
    private let openSettings: () -> Void

    private let panel = NotchPanel()
    private lazy var framer = WindowFramer(window: panel)
    private let hover = HoverIntent()
    private let input = ExpandedInputMonitor()

    /// Last presentation reported by the view; drives the window frame.
    private var presentation: Presentation = .closed
    private var hasSecondary = false
    /// App that was frontmost before expanding; gets keyboard focus back on collapse.
    private var previousApp: NSRunningApplication?

    init(screen: NSScreen, registry: PluginRegistry, settings: AppSettings, openSettings: @escaping () -> Void) {
        self.store = NotchStore(geometry: NotchGeometry(screen: screen))
        self.registry = registry
        self.settings = settings
        self.openSettings = openSettings

        panel.contentView = makeHostingView()
        wireInput()
        applySettings()
        placeWindow(deferShrink: false)
        panel.orderFrontRegardless()
    }

    // MARK: - Lifecycle

    func close() {
        input.stop()
        hover.cancel()
        panel.orderOut(nil)
        panel.contentView = nil
    }

    /// Returns true when the screen's geometry actually changed.
    @discardableResult
    func update(screen: NSScreen) -> Bool {
        let geometry = NotchGeometry(screen: screen)
        guard geometry != store.geometry else { return false }
        store.geometry = geometry
        placeWindow(deferShrink: false)
        return true
    }

    func applySettings() {
        panel.sharingType = settings.hideFromCapture ? .none : .readOnly
    }

    // MARK: - Commands from the app

    func setSuspended(_ suspended: Bool) {
        guard suspended != store.suspended else { return }
        if suspended { collapse() }
        store.suspended = suspended
        if suspended { panel.orderOut(nil) } else { panel.orderFrontRegardless() }
    }

    /// After wake or a display change: forget stale hover and peek state (the "stuck after sleep" bug).
    func resetTransientState() {
        hover.cancel()
        store.peekPluginID = nil
        collapse()
    }

    func peek(_ pluginID: String, seconds: TimeInterval) {
        guard store.mode == .closed, !store.suspended else { return }
        store.peekPluginID = pluginID
        registry.scheduler.schedule(id: "host.peek.\(store.geometry.displayID)", at: .now + seconds) { [weak self] in
            self?.store.peekPluginID = nil
        }
    }

    func setEditing(_ editing: Bool) {
        store.editing = editing
    }

    // MARK: - Expand / collapse

    func expand() {
        guard store.mode == .closed, !store.suspended else { return }
        previousApp = NSWorkspace.shared.frontmostApplication
        store.peekPluginID = nil
        store.mode = .expanded
        panel.allowsKey = true
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        input.start(for: panel)
    }

    /// - Parameter returnFocus: re-activate the app that was in front before expanding. Pass false when
    ///   the collapse comes from a click in another app: that click already chose where focus goes.
    func collapse(returnFocus: Bool = true) {
        guard store.mode == .expanded else { return }
        store.mode = .closed
        store.editing = false
        store.selectedPage = nil
        input.stop()
        releaseKeyFocus(returnToPreviousApp: returnFocus)
    }

    /// If clicking or typing made the panel key, give the keyboard up (and optionally back to the previous app).
    private func releaseKeyFocus(returnToPreviousApp: Bool) {
        let wasKey = panel.isKeyWindow
        panel.allowsKey = false
        guard wasKey else { return }
        panel.resignKey()
        guard returnToPreviousApp, previousApp?.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
        previousApp?.activate()
    }

    // MARK: - Wiring

    private func makeHostingView() -> NSView {
        let actions = NotchActions(
            presentationChanged: { [weak self] presentation, hasSecondary in
                self?.presentationChanged(presentation, hasSecondary: hasSecondary)
            },
            expand: { [weak self] in self?.expand() },
            openSettings: { [weak self] in self?.showSettings() }
        )
        let view = NotchHostingView(rootView: NotchRootView(store: store, registry: registry, actions: actions))
        view.onHover = { [weak self] inside in self?.pointer(inside: inside) }
        view.menuProvider = { [weak self] in
            NotchContextMenu.make(openSettings: { self?.showSettings() })
        }
        return view
    }

    private func wireInput() {
        hover.onOpen = { [weak self] in self?.expand() }
        hover.onClose = { [weak self] in self?.collapse() }
        input.onClickOutside = { [weak self] in self?.collapse(returnFocus: false) }
        input.onEscape = { [weak self] in self?.collapse() }
        input.onSwipe = { [weak self] delta in self?.store.turnPage(by: delta) }
    }

    private func pointer(inside: Bool) {
        hover.pointer(
            inside: inside,
            canOpen: store.mode == .closed && settings.hoverToExpand,
            canClose: store.mode == .expanded && !store.editing
        )
    }

    private func showSettings() {
        collapse()
        openSettings()
    }

    // MARK: - Window frame

    private func presentationChanged(_ presentation: Presentation, hasSecondary: Bool) {
        self.presentation = presentation
        self.hasSecondary = hasSecondary
        placeWindow(deferShrink: true)
    }

    private func placeWindow(deferShrink: Bool) {
        let canvas = NotchLayout(geometry: store.geometry).canvas(presentation, hasSecondary: hasSecondary)
        let frame = store.geometry.windowFrame(canvas: canvas, hidden: presentation == .hidden)
        framer.setFrame(frame, deferShrink: deferShrink)
    }
}
