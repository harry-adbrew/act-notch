import Foundation
import Testing
@testable import TodoPlugin

@Suite struct QuickAddParserTests {
    @Test func relativeDuration() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let result = QuickAddParser.parse("call mom in 10m", now: now)
        #expect(result.title == "call mom")
        #expect(result.due == now + 600)
    }

    @Test func pastTimeTodayRollsToTomorrow() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 18)))

        let result = QuickAddParser.parse("standup at 9am", now: now, calendar: calendar)

        #expect(result.title == "standup")
        let due = try #require(result.due)
        #expect(due > now)
        #expect(calendar.component(.hour, from: due) == 9)
    }

    @Test func plainTextHasNoDueDate() {
        let result = QuickAddParser.parse("  buy milk ")
        #expect(result.title == "buy milk")
        #expect(result.due == nil)
    }

    @Test func displayOrderPutsDatedFirst() {
        let base = Date(timeIntervalSince1970: 1_000_000)
        let undated = Todo(title: "undated", createdAt: base)
        let later = Todo(title: "later", due: base + 600)
        let sooner = Todo(title: "sooner", due: base + 60)

        #expect([undated, later, sooner].displayOrder().map(\.title) == ["sooner", "later", "undated"])
    }
}
