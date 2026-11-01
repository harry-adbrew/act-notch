import DyaNotchKit
import SwiftUI

/// One todo: tap the circle to complete (strike-through, then it slides out); trash appears on hover.
struct TodoRow: View {
    let todo: Todo
    let plugin: TodoPlugin
    @State private var hovering = false

    var body: some View {
        HStack(spacing: DN.Space.s) {
            completeButton

            Text(todo.title)
                .font(DN.Typography.bodyLarge)
                .foregroundStyle(todo.done ? DN.Palette.textTertiary : DN.Palette.textPrimary)
                .strikethrough(todo.done)
                .lineLimit(1)

            Spacer(minLength: DN.Space.s)

            trailing
        }
        .padding(.horizontal, DN.Space.s)
        .frame(height: 26)
        .background(
            RoundedRectangle(cornerRadius: DN.Radius.row, style: .continuous)
                .fill(Color.white.opacity(hovering ? 0.06 : 0))
        )
        .onHover { hovering = $0 }
        .contextMenu {
            Button("Delete", role: .destructive) { plugin.delete(todo.id) }
        }
        .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .trailing).combined(with: .opacity)))
    }

    private var completeButton: some View {
        Button { plugin.complete(todo.id) } label: {
            Image(systemName: todo.done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 15))
                .foregroundStyle(todo.done ? DN.Palette.success : DN.Palette.textSecondary)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(PressableStyle())
    }

    /// Trash while hovered, otherwise the due label.
    @ViewBuilder
    private var trailing: some View {
        if hovering {
            Button { plugin.delete(todo.id) } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundStyle(DN.Palette.textTertiary)
            }
            .buttonStyle(PressableStyle())
            .transition(.opacity)
        } else if let due = todo.due, !todo.done {
            DueLabel(due: due, font: DN.Typography.caption)
        }
    }
}
