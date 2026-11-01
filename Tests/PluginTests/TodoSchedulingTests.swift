import DyaNotchKit
import Foundation
import Testing
@testable import TodoPlugin

/// The todo's journey through the notch: nothing → "soon" (15 min before) → urgent + peek (at due time).
@MainActor
@Suite struct TodoSchedulingTests {
    @Test func todoBecomesSoonThenUrgentAndPeeksOnce() async throws {
        let context = FakePluginContext()
        let plugin = TodoPlugin()
        try await plugin.activate(context)

        let todo = try #require(plugin.add("call mom in 20m"))
        #expect(plugin.activity == nil) // 20 min away: not yet

        context.advance(by: 6 * 60) // 14 min left
        let soon = try #require(plugin.activity)
        #expect(soon.priority == .normal)
        #expect(context.peeks.isEmpty)

        context.advance(by: 15 * 60) // past due
        let due = try #require(plugin.activity)
        #expect(due.priority == .urgent)
        #expect(due.id == "todo-\(todo.id)")
        #expect(context.peeks.count == 1)
    }

    @Test func completingCancelsItsJobs() async throws {
        let context = FakePluginContext()
        let plugin = TodoPlugin()
        try await plugin.activate(context)

        let todo = try #require(plugin.add("call mom in 20m"))
        plugin.complete(todo.id)
        context.advance(by: 30 * 60)

        #expect(plugin.activity == nil)
        #expect(context.peeks.isEmpty)
        #expect(plugin.todos.isEmpty) // purged after the strike-through
    }

    @Test func undatedTodoNeverClaimsTheNotch() async throws {
        let context = FakePluginContext()
        let plugin = TodoPlugin()
        try await plugin.activate(context)

        plugin.add("buy milk")
        context.advance(by: 24 * 3600)

        #expect(plugin.activity == nil)
        #expect(context.scheduler.scheduledIDs.isEmpty)
    }
}
