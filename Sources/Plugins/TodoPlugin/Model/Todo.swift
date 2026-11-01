import Foundation

public struct Todo: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var due: Date?
    public var done: Bool
    public var createdAt: Date

    public init(id: UUID = UUID(), title: String, due: Date? = nil, done: Bool = false, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.due = due
        self.done = done
        self.createdAt = createdAt
    }

    public func isOverdue(at now: Date) -> Bool {
        guard !done, let due else { return false }
        return due <= now
    }

    /// Overdue, or due within `window`. These claim the compact notch.
    public func isUrgent(at now: Date, window: TimeInterval) -> Bool {
        guard !done, let due else { return false }
        return due.timeIntervalSince(now) <= window
    }
}

extension Array where Element == Todo {
    /// Display order: dated todos by due date (overdue first), then undated ones, newest first.
    func displayOrder() -> [Todo] {
        sorted { a, b in
            switch (a.due, b.due) {
            case let (x?, y?): x < y
            case (.some, nil): true
            case (nil, .some): false
            case (nil, nil): a.createdAt > b.createdAt
            }
        }
    }
}
