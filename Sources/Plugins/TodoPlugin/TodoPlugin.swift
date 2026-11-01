import DyaNotchKit
import Foundation
import Observation

/// Local todos with optional due times, stored in `todo/todos.json`.
///
/// Scheduling, two jobs per dated todo:
/// - `soon-<id>` at `due − soonWindow` → the todo starts claiming the compact notch
/// - `due-<id>`  at `due`              → it turns urgent and the notch peeks
/// Both set `clock` to their own threshold date, which `activity` reads, so Observation re-renders at
/// exactly those moments and the result does not depend on how late the job ran.
@MainActor
@Observable
public final class TodoPlugin: NotchPlugin {
    public static let manifest = PluginManifest(
        id: "todo",
        name: "Todos",
        symbol: "checklist",
        summary: "Quick todos with due times (\"call mom in 10m\"). Stored locally."
    )

    /// Todos that are overdue, or due within this window, claim the compact notch.
    static let soonWindow: TimeInterval = 15 * 60
    /// How long a completed row stays visible (strike-through) before it is removed.
    static let completedLinger: TimeInterval = 0.8

    public private(set) var todos: [Todo] = []
    /// Most recent todo that came due; shown in the peek.
    private(set) var justDue: UUID?
    /// "Now", as of the last scheduled threshold. Bumping it is what re-evaluates `activity`.
    private var clock = Date()
    @ObservationIgnored private var context: PluginContext?

    public init() {}

    // MARK: - Lifecycle

    public func activate(_ context: PluginContext) async throws {
        self.context = context
        // Completed todos are kept for one session only.
        todos = (context.storage.load([Todo].self, from: "todos") ?? []).filter { !$0.done }
        todos.forEach(arm)
        clock = .now
    }

    public func deactivate() {
        todos.forEach(disarm)
        context = nil
    }

    // MARK: - Activity

    public var activity: LiveActivity? {
        guard let next = urgentTodos.first else { return nil }
        let overdue = next.isOverdue(at: clock)
        return LiveActivity(
            id: "todo-\(next.id)",
            priority: overdue ? .urgent : .normal,
            since: next.due ?? next.createdAt,
            tint: overdue ? DN.Palette.danger : DN.Palette.todo
        )
    }

    /// Overdue or due-soon todos, earliest first.
    var urgentTodos: [Todo] {
        todos.filter { $0.isUrgent(at: clock, window: Self.soonWindow) }
            .sorted { ($0.due ?? .distantFuture) < ($1.due ?? .distantFuture) }
    }

    /// The todo to show in a peek: the one that just came due, else the most urgent.
    var peekTodo: Todo? {
        justDue.flatMap { id in todos.first { $0.id == id && !$0.done } } ?? urgentTodos.first
    }

    // MARK: - Commands

    /// Parses and adds a todo. Returns nil when the text has no title.
    @discardableResult
    public func add(_ text: String) -> Todo? {
        let parsed = QuickAddParser.parse(text)
        guard !parsed.title.isEmpty else { return nil }
        let todo = Todo(title: parsed.title, due: parsed.due)
        todos.append(todo)
        arm(todo)
        clock = .now
        persist()
        return todo
    }

    func complete(_ id: UUID) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].done = true
        disarm(todos[index])
        clock = .now
        persist()
        // Let the strike-through play, then slide the row out.
        context?.schedule(at: .now.addingTimeInterval(Self.completedLinger), id: "purge-\(id)") { [weak self] in
            self?.todos.removeAll { $0.id == id }
        }
    }

    func delete(_ id: UUID) {
        guard let todo = todos.first(where: { $0.id == id }) else { return }
        disarm(todo)
        todos.removeAll { $0.id == id }
        clock = .now
        persist()
    }

    /// Forwards text-field focus to the host so the island stays open while typing.
    func setEditing(_ editing: Bool) {
        context?.setWantsKeyboard(editing)
    }

    // MARK: - Scheduling

    private func arm(_ todo: Todo) {
        guard let context, let due = todo.due, !todo.done else { return }
        let soon = due.addingTimeInterval(-Self.soonWindow)
        if soon > .now {
            context.schedule(at: soon, id: "soon-\(todo.id)") { [weak self] in self?.advanceClock(to: soon) }
        }
        if due > .now {
            context.schedule(at: due, id: "due-\(todo.id)") { [weak self] in self?.becameDue(todo.id, at: due) }
        }
    }

    private func disarm(_ todo: Todo) {
        context?.cancel(id: "soon-\(todo.id)")
        context?.cancel(id: "due-\(todo.id)")
    }

    /// Moves `clock` forward to at least `date` (never backwards: a late job must not undo a newer bump).
    private func advanceClock(to date: Date) {
        clock = max(clock, date, .now)
    }

    private func becameDue(_ id: UUID, at due: Date) {
        advanceClock(to: due)
        justDue = id
        context?.requestPeek(seconds: 4)
    }

    private func persist() {
        context?.storage.save(todos, to: "todos")
    }
}
