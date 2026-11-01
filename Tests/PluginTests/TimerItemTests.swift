import Foundation
import Testing
@testable import TimerPlugin

@Suite struct TimerItemTests {
    let start = Date(timeIntervalSince1970: 1_000_000)

    @Test func remainingIsEndDateBased() {
        let timer = TimerItem(label: "t", duration: 300, start: start)
        #expect(timer.remaining(at: start + 100) == 200)
        #expect(timer.remaining(at: start + 400) == 0)
        #expect(abs(timer.fraction(at: start + 150) - 0.5) < 0.0001)
    }

    @Test func pauseFreezesAndResumeShiftsEnd() {
        var timer = TimerItem(label: "t", duration: 300, start: start)
        timer.pause(at: start + 100)
        #expect(timer.isPaused && !timer.isRunning)
        #expect(timer.remaining(at: start + 1000) == 200)

        timer.resume(at: start + 1000)
        #expect(timer.endDate == start + 1200)
        #expect(timer.remaining(at: start + 1100) == 100)
    }

    @Test func extendRestartsFinishedTimer() {
        var timer = TimerItem(label: "t", duration: 60, start: start)
        timer.finishedAt = start + 60
        timer.extend(by: 60, at: start + 70)
        #expect(!timer.isFinished)
        #expect(timer.remaining(at: start + 70) == 60)
    }

    @Test func restoreFinishesTimersThatEndedWhileClosed() {
        let ended = TimerItem(label: "ended", duration: 60, start: start)
        let running = TimerItem(label: "running", duration: 600, start: start)
        var stale = TimerItem(label: "stale", duration: 60, start: start)
        stale.finishedAt = start + 60

        let restored = TimerPlugin.restore([ended, running, stale], now: start + 300)

        #expect(restored.map(\.label) == ["ended", "running"])
        #expect(restored[0].isFinished)
        #expect(restored[1].isRunning)
    }
}
