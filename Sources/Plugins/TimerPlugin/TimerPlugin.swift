import AppKit
import DyaNotchKit
import Observation

/// Countdown timers. Several can run at once; every timer is defined by dates, so nothing ticks.
///
/// Scheduling, one job per timer (job id = timer uuid):
/// - running  → fire at `endDate`, which marks it finished
/// - finished → remove it `finishedLinger` seconds later
/// - paused   → no job
@MainActor
@Observable
public final class TimerPlugin: NotchPlugin {
    public static let manifest = PluginManifest(
        id: "timer",
        name: "Timers",
        symbol: "timer",
        summary: "Countdown timers with presets. Several at once, survives sleep."
    )

    public static let presets: [TimeInterval] = [60, 5 * 60, 10 * 60, 25 * 60]
    /// A finished timer keeps claiming the notch for this long unless dismissed.
    nonisolated static let finishedLinger: TimeInterval = 120

    public private(set) var timers: [TimerItem] = []
    @ObservationIgnored private var context: PluginContext?

    public init() {}

    // MARK: - Lifecycle

    public func activate(_ context: PluginContext) async throws {
        self.context = context
        timers = Self.restore(context.storage.load([TimerItem].self, from: "timers") ?? [], now: .now)
        timers.forEach(arm)
    }

    public func deactivate() {
        timers.forEach { context?.cancel(id: $0.id.uuidString) }
        context = nil
    }

    /// Drops long-finished timers, and silently finishes timers that ended while the app was closed.
    nonisolated static func restore(_ saved: [TimerItem], now: Date) -> [TimerItem] {
        saved
            .filter { item in
                guard let finishedAt = item.finishedAt else { return true }
                return now.timeIntervalSince(finishedAt) <= finishedLinger
            }
            .map { item in
                var item = item
                if item.isRunning, item.remaining(at: now) == 0 { item.finishedAt = item.endDate }
                return item
            }
    }

    // MARK: - Activity

    public var activity: LiveActivity? {
        if let done = latestFinished, let finishedAt = done.finishedAt {
            return LiveActivity(
                id: "done-\(done.id)",
                priority: .urgent,
                since: finishedAt,
                expiresAt: finishedAt.addingTimeInterval(Self.finishedLinger),
                tint: DN.Palette.timer
            )
        }
        guard let next = featured else { return nil }
        return LiveActivity(id: "run-\(next.id)", priority: .normal, since: .distantPast, tint: DN.Palette.timer)
    }

    /// The timer the compact and peek views show: a finished one first, else the one ending soonest.
    var featured: TimerItem? {
        if let done = timers.first(where: \.isFinished) { return done }
        let now = Date()
        return timers.filter { !$0.isFinished }.min { $0.remaining(at: now) < $1.remaining(at: now) }
    }

    private var latestFinished: TimerItem? {
        timers.filter(\.isFinished).max { ($0.finishedAt ?? .distantPast) < ($1.finishedAt ?? .distantPast) }
    }

    // MARK: - Commands

    public func start(_ duration: TimeInterval, label: String? = nil) {
        let item = TimerItem(label: label ?? Self.label(for: duration), duration: duration, start: .now)
        timers.append(item)
        arm(item)
        persist()
    }

    func togglePause(_ id: UUID) {
        update(id) { $0.isPaused ? $0.resume(at: .now) : $0.pause(at: .now) }
    }

    func extend(_ id: UUID, by seconds: TimeInterval = 60) {
        update(id) { $0.extend(by: seconds, at: .now) }
    }

    func remove(_ id: UUID) {
        context?.cancel(id: id.uuidString)
        timers.removeAll { $0.id == id }
        persist()
    }

    private func update(_ id: UUID, _ change: (inout TimerItem) -> Void) {
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        change(&timers[index])
        arm(timers[index])
        persist()
    }

    // MARK: - Scheduling

    private func arm(_ item: TimerItem) {
        guard let context else { return }
        let jobID = item.id.uuidString
        if let finishedAt = item.finishedAt {
            context.schedule(at: finishedAt.addingTimeInterval(Self.finishedLinger), id: jobID) { [weak self] in
                self?.remove(item.id)
            }
        } else if let end = item.endDate {
            context.schedule(at: end, id: jobID) { [weak self] in self?.finish(item.id) }
        } else {
            context.cancel(id: jobID)
        }
    }

    private func finish(_ id: UUID) {
        guard let index = timers.firstIndex(where: { $0.id == id }), timers[index].isRunning else { return }
        timers[index].finishedAt = .now
        arm(timers[index])
        persist()
        NSSound(named: "Glass")?.play()
        context?.requestPeek(seconds: 4)
    }

    private func persist() {
        context?.storage.save(timers, to: "timers")
    }

    // MARK: - Helpers

    /// "5m", "1h 30m": the default label for a duration.
    static func label(for duration: TimeInterval) -> String {
        labelFormatter.string(from: duration) ?? "Timer"
    }

    private static let labelFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    /// Shared `matchedGeometryEffect` id for a timer's ring (compact ⇄ expanded).
    static func ringID(_ id: UUID) -> String { "timer-ring-\(id)" }
}
