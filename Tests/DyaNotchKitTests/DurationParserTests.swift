import DyaNotchKit
import Foundation
import Testing

@Suite struct DurationParserTests {
    @Test(arguments: [
        ("90s", 90.0), ("10m", 600), ("1h30m", 5400), ("1h 30 min", 5400), ("2 hours", 7200),
        ("1:30", 90), ("25", 1500), ("0.5h", 1800),
    ])
    func parsesDurations(input: String, expected: TimeInterval) {
        #expect(DurationParser.parse(input) == expected)
    }

    @Test(arguments: ["", "abc", "10 bananas", "0", "-5"])
    func rejectsGarbage(input: String) {
        #expect(DurationParser.parse(input) == nil)
    }

    @Test func formatsClock() {
        #expect(DurationParser.clock(59.2) == "1:00")
        #expect(DurationParser.clock(3725) == "1:02:05")
    }
}
