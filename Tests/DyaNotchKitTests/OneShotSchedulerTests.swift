import DyaNotchKit
import Foundation
import Testing

@MainActor
@Suite struct OneShotSchedulerTests {
    final class Clock { var now = Date(timeIntervalSince1970: 1_000_000) }

    @Test func firesOnlyDueJobsInOrder() {
        let clock = Clock()
        let scheduler = OneShotScheduler(now: { clock.now }, armsTimers: false)
        var fired: [String] = []
        scheduler.schedule(id: "b", at: clock.now + 20) { fired.append("b") }
        scheduler.schedule(id: "a", at: clock.now + 10) { fired.append("a") }
        scheduler.schedule(id: "c", at: clock.now + 60) { fired.append("c") }

        clock.now += 30 // e.g. the Mac slept through two deadlines
        scheduler.rearm()

        #expect(fired == ["a", "b"])
        #expect(scheduler.scheduledIDs == ["c"])
    }

    @Test func rescheduleReplacesAndCancelRemoves() {
        let clock = Clock()
        let scheduler = OneShotScheduler(now: { clock.now }, armsTimers: false)
        var fired: [String] = []
        scheduler.schedule(id: "x", at: clock.now + 5) { fired.append("old") }
        scheduler.schedule(id: "x", at: clock.now + 5) { fired.append("new") }
        scheduler.schedule(id: "plugin.y", at: clock.now + 5) { fired.append("y") }
        scheduler.cancelAll(prefix: "plugin.")

        clock.now += 10
        scheduler.fireDue()

        #expect(fired == ["new"])
    }
}
