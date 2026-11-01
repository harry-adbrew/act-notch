import Foundation

/// End-date based timer: nothing ticks, so it never drifts and survives sleep and relaunch.
public struct TimerItem: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var label: String
    public var duration: TimeInterval
    /// When running: the wall-clock end. When paused: nil.
    public var endDate: Date?
    /// When paused: the time that was left.
    public var pausedRemaining: TimeInterval?
    /// Set once the timer reaches zero; cleared on dismiss.
    public var finishedAt: Date?

    public init(id: UUID = UUID(), label: String, duration: TimeInterval, start: Date) {
        self.id = id
        self.label = label
        self.duration = duration
        self.endDate = start.addingTimeInterval(duration)
        self.pausedRemaining = nil
        self.finishedAt = nil
    }

    public var isRunning: Bool { endDate != nil && finishedAt == nil }
    public var isPaused: Bool { pausedRemaining != nil }
    public var isFinished: Bool { finishedAt != nil }

    public func remaining(at now: Date) -> TimeInterval {
        if isFinished { return 0 }
        if let pausedRemaining { return pausedRemaining }
        guard let endDate else { return 0 }
        return max(0, endDate.timeIntervalSince(now))
    }

    /// Remaining fraction, 1 = just started.
    public func fraction(at now: Date) -> Double {
        guard duration > 0 else { return 0 }
        return remaining(at: now) / duration
    }

    public mutating func pause(at now: Date) {
        guard isRunning else { return }
        pausedRemaining = remaining(at: now)
        endDate = nil
    }

    public mutating func resume(at now: Date) {
        guard let left = pausedRemaining else { return }
        endDate = now.addingTimeInterval(left)
        pausedRemaining = nil
    }

    /// Adds time; restarts a finished timer.
    public mutating func extend(by seconds: TimeInterval, at now: Date) {
        if isFinished {
            finishedAt = nil
            duration = seconds
            endDate = now.addingTimeInterval(seconds)
        } else if let left = pausedRemaining {
            pausedRemaining = left + seconds
            duration += seconds
        } else if let end = endDate {
            endDate = end.addingTimeInterval(seconds)
            duration += seconds
        }
    }
}
