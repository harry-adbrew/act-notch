import DyaNotchKit
import Foundation
import Testing

@Suite struct ActivityArbiterTests {
    let t0 = Date(timeIntervalSince1970: 1_000_000)

    private func candidate(
        _ id: String,
        _ priority: LiveActivity.Priority,
        since: TimeInterval = 0,
        expires: TimeInterval? = nil
    ) -> ActivityCandidate {
        ActivityCandidate(pluginID: id, activity: LiveActivity(
            id: id, priority: priority, since: t0 + since, expiresAt: expires.map { t0 + $0 }
        ))
    }

    @Test func urgentBeatsAmbient() {
        let result = ActivityArbiter.resolve([candidate("spotify", .ambient), candidate("timer", .urgent)], now: t0)
        #expect(result.primary?.pluginID == "timer")
        #expect(result.secondary?.pluginID == "spotify")
    }

    @Test func recencyBreaksTies() {
        let result = ActivityArbiter.resolve([candidate("a", .normal, since: 1), candidate("b", .normal, since: 5)], now: t0)
        #expect(result.primary?.pluginID == "b")
    }

    @Test func expiredIsDropped() {
        let result = ActivityArbiter.resolve([candidate("a", .urgent, expires: 10), candidate("b", .ambient)], now: t0 + 11)
        #expect(result.primary?.pluginID == "b")
        #expect(result.secondary == nil)
    }

    @Test func emptyResolvesToNothing() {
        let result = ActivityArbiter.resolve([], now: t0)
        #expect(result.primary == nil && result.secondary == nil)
    }
}
