import Foundation

/// One-shot jobs at wall-clock dates. There is no repeating timer in the app; anything periodic is
/// derived in views from dates.
///
/// Each job arms a `DispatchSourceTimer` on a *wall* deadline, so a deadline that passes while the Mac
/// sleeps fires right after wake. `rearm()` is also called on wake as a belt-and-braces sweep.
@MainActor
public final class OneShotScheduler {
    private struct Job {
        let date: Date
        let fire: @MainActor () -> Void
        var timer: DispatchSourceTimer?
    }

    private var jobs: [String: Job] = [:]
    private let now: () -> Date
    private let armsTimers: Bool

    /// - Parameter armsTimers: `false` in tests, which drive time through `fireDue()`.
    public init(now: @escaping () -> Date = Date.init, armsTimers: Bool = true) {
        self.now = now
        self.armsTimers = armsTimers
    }

    public var scheduledIDs: Set<String> { Set(jobs.keys) }

    public func schedule(id: String, at date: Date, _ fire: @escaping @MainActor () -> Void) {
        cancel(id: id)
        jobs[id] = Job(date: date, fire: fire, timer: nil)
        arm(id)
    }

    public func cancel(id: String) {
        jobs.removeValue(forKey: id)?.timer?.cancel()
    }

    public func cancelAll(prefix: String) {
        for id in jobs.keys where id.hasPrefix(prefix) { cancel(id: id) }
    }

    /// Fires every job whose date has passed and re-arms the rest. Returns the ids that fired.
    @discardableResult
    public func rearm() -> [String] {
        let fired = fireDue()
        for id in jobs.keys { arm(id) }
        return fired
    }

    @discardableResult
    public func fireDue() -> [String] {
        let t = now()
        let due = jobs.filter { $0.value.date <= t }.sorted { $0.value.date < $1.value.date }
        for (id, job) in due {
            job.timer?.cancel()
            jobs[id] = nil
            job.fire()
        }
        return due.map(\.key)
    }

    private func arm(_ id: String) {
        guard armsTimers, var job = jobs[id] else { return }
        job.timer?.cancel()
        let delay = max(0, job.date.timeIntervalSince(now()))
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(wallDeadline: .now() + delay, leeway: .milliseconds(100))
        timer.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.fireOne(id) }
        }
        job.timer = timer
        jobs[id] = job
        timer.resume()
    }

    private func fireOne(_ id: String) {
        guard let job = jobs.removeValue(forKey: id) else { return }
        job.timer?.cancel()
        job.fire()
    }
}
