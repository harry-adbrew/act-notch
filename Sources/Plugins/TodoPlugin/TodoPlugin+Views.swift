import DyaNotchKit
import SwiftUI

/// The island surfaces for todos: status glyph | due label in compact (only when something is due
/// soon or overdue), title + due in peek, quick-add + list in expanded.
extension TodoPlugin {
    public func compactLeading(_ ctx: NotchViewContext) -> AnyView? {
        guard let todo = urgentTodos.first else { return nil }
        let overdue = todo.isOverdue(at: .now)
        return AnyView(
            Image(systemName: overdue ? "exclamationmark.circle.fill" : "circle.dashed")
                .font(.system(size: DN.Icon.compact, weight: .semibold))
                .foregroundStyle(overdue ? DN.Palette.danger : DN.Palette.todo)
        )
    }

    public func compactTrailing(_ ctx: NotchViewContext) -> AnyView? {
        let urgent = urgentTodos
        guard let due = urgent.first?.due else { return nil }
        return AnyView(DueLabel(due: due, additional: urgent.count - 1, font: DN.Typography.compactValue))
    }

    public func peekView(_ ctx: NotchViewContext) -> AnyView? {
        guard let todo = peekTodo else { return nil }
        return AnyView(
            HStack(spacing: DN.Space.s) {
                Image(systemName: "checklist")
                    .foregroundStyle(DN.Palette.todo)
                Text(todo.title)
                    .font(DN.Typography.title)
                    .foregroundStyle(DN.Palette.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let due = todo.due {
                    DueLabel(due: due, font: DN.Typography.caption)
                }
            }
        )
    }

    public func expandedView(_ ctx: NotchViewContext) -> AnyView? {
        AnyView(TodoPage(plugin: self, onEditing: { [weak self] in self?.setEditing($0) }))
    }
}
