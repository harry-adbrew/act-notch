import DyaNotchKit
import SwiftUI

/// Expanded page: quick-add field on top, list below.
struct TodoPage: View {
    let plugin: TodoPlugin
    /// Reports text-field focus so the island stays open while typing.
    let onEditing: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DN.Space.s) {
            QuickAddField(plugin: plugin, onEditing: onEditing)
            list
        }
        .animation(DN.Motion.swap, value: plugin.todos)
        .onDisappear { onEditing(false) }
    }

    @ViewBuilder
    private var list: some View {
        if plugin.todos.isEmpty {
            Text("Nothing to do. Nice.")
                .font(DN.Typography.body)
                .foregroundStyle(DN.Palette.textTertiary)
                .frame(maxWidth: .infinity, minHeight: 60)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 2) {
                    ForEach(plugin.todos.displayOrder()) { TodoRow(todo: $0, plugin: plugin) }
                }
            }
            .frame(maxHeight: 112)
        }
    }
}

private struct QuickAddField: View {
    let plugin: TodoPlugin
    let onEditing: (Bool) -> Void
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: DN.Space.s) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: DN.Icon.expanded))
                .foregroundStyle(DN.Palette.todo)
            TextField("Add a todo — \u{201C}call mom in 10m\u{201D}, \u{201C}standup at 9:30\u{201D}", text: $draft)
                .textFieldStyle(.plain)
                .font(DN.Typography.bodyLarge)
                .focused($focused)
                .onSubmit(submit)
        }
        .padding(.horizontal, DN.Space.m)
        .frame(height: 32)
        .background(RoundedRectangle(cornerRadius: DN.Radius.button, style: .continuous).fill(DN.Palette.surface))
        .onChange(of: focused) { _, isFocused in onEditing(isFocused) }
    }

    private func submit() {
        if plugin.add(draft) != nil { draft = "" }
    }
}
