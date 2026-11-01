import Foundation

/// Turns raw enter/exit events into deliberate open/close intents:
/// - entering opens after `openDelay` (cancelled if the pointer leaves first), so brushing past does nothing;
/// - leaving closes after `closeDelay` (cancelled if the pointer comes back).
@MainActor
final class HoverIntent {
    static let openDelay: TimeInterval = 0.12
    static let closeDelay: TimeInterval = 0.3

    var onOpen: () -> Void = {}
    var onClose: () -> Void = {}

    private var pending: DispatchWorkItem?

    /// - Parameters:
    ///   - canOpen: whether entering should lead to opening (e.g. closed and hover-to-expand is on).
    ///   - canClose: whether leaving should lead to closing (e.g. expanded and not typing).
    func pointer(inside: Bool, canOpen: Bool, canClose: Bool) {
        cancel()
        if inside, canOpen {
            schedule(after: Self.openDelay) { [weak self] in self?.onOpen() }
        } else if !inside, canClose {
            schedule(after: Self.closeDelay) { [weak self] in self?.onClose() }
        }
    }

    func cancel() {
        pending?.cancel()
        pending = nil
    }

    private func schedule(after delay: TimeInterval, _ action: @escaping @MainActor () -> Void) {
        let work = DispatchWorkItem { MainActor.assumeIsolated(action) }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
}
