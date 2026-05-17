import SwiftUI

struct WeekDetailView: View {
    @EnvironmentObject var store: AppStore
    let plan: WeeklyPlan
    let goalId: UUID

    @State private var newTodoText = ""
    @State private var editingActionId: UUID? = nil
    @State private var editingText = ""
    @FocusState private var todoFocused: Bool
    @FocusState private var editFocused: Bool

    private var livePlan: WeeklyPlan? {
        store.goals.first(where: { $0.id == goalId })?
            .weeklyPlans.first(where: { $0.id == plan.id })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Theme + Focus
                VStack(alignment: .leading, spacing: 6) {
                    Text(livePlan?.theme ?? plan.theme)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentTeal)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Text(livePlan?.focus ?? plan.focus)
                        .font(.system(.title3, design: .serif, weight: .regular))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentTeal.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.accentTeal.opacity(0.2), lineWidth: 1))

                // AI Actions (editable)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("This week's actions", systemImage: "sparkles")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Tap to edit")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 0) {
                        ForEach(livePlan?.actions ?? plan.actions) { action in
                            if editingActionId == action.id {
                                // Inline edit mode
                                HStack(spacing: 10) {
                                    TextField("Edit action…", text: $editingText)
                                        .font(.subheadline)
                                        .focused($editFocused)
                                    Button("Done") {
                                        store.editAction(goalId: goalId, weekId: plan.id,
                                                         actionId: action.id, newText: editingText)
                                        editingActionId = nil
                                    }
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.accentTeal)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                            } else {
                                ActionRow(action: action, goalId: goalId, weekId: plan.id) {
                                    editingActionId = action.id
                                    editingText = action.text
                                    editFocused = true
                                }
                            }

                            if action.id != (livePlan?.actions ?? plan.actions).last?.id {
                                Divider().padding(.leading, 46)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5))
                }

                // Checkpoint
                VStack(alignment: .leading, spacing: 6) {
                    Label("How you'll know you succeeded", systemImage: "flag")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(livePlan?.checkpoint ?? plan.checkpoint)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Personal Todos
                VStack(alignment: .leading, spacing: 10) {
                    Label("My personal tasks", systemImage: "list.bullet")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        TextField("Add your own task…", text: $newTodoText)
                            .font(.subheadline)
                            .focused($todoFocused)
                            .onSubmit { addTodo() }

                        Button(action: addTodo) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(newTodoText.isEmpty ? Color(.secondaryLabel) : Color.accentTeal)
                        }
                        .disabled(newTodoText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(todoFocused ? Color.accentTeal : Color(.separator).opacity(0.4),
                                      lineWidth: todoFocused ? 1.5 : 0.5))

                    if let todos = livePlan?.personalTodos, !todos.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(todos) { todo in
                                WeekTodoRow(todo: todo, goalId: goalId, weekId: plan.id)
                                if todo.id != todos.last?.id { Divider().padding(.leading, 46) }
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5))
                    } else {
                        Text("Add tasks that are specific to your situation")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }

                // Complete week button
                if !(livePlan?.isComplete ?? plan.isComplete) {
                    Button {
                        store.completeWeek(goalId: goalId, weekId: plan.id)
                    } label: {
                        Label("Mark week complete", systemImage: "checkmark.circle.fill")
                            .font(.body.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentTeal)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    Label("Week complete!", systemImage: "checkmark.circle.fill")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentTeal.opacity(0.12))
                        .foregroundStyle(Color.accentTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(16)
        }
        .navigationTitle("Week \(plan.week)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addTodo() {
        let text = newTodoText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        // Add personal todo to this week plan
        guard let gi = store.goals.firstIndex(where: { $0.id == goalId }),
              let wi = store.goals[gi].weeklyPlans.firstIndex(where: { $0.id == plan.id }) else { return }
        store.goals[gi].weeklyPlans[wi].personalTodos.append(DailyTodo(text: text))
        store.updateGoal(store.goals[gi])
        newTodoText = ""
    }
}

// MARK: - Action Row (editable)

struct ActionRow: View {
    @EnvironmentObject var store: AppStore
    let action: ActionItem
    let goalId: UUID
    let weekId: UUID
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                store.toggleAction(goalId: goalId, weekId: weekId, actionId: action.id)
            } label: {
                Image(systemName: action.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(action.isComplete ? Color.accentTeal : Color(.secondaryLabel))
            }
            .buttonStyle(.plain)

            Text(action.text)
                .font(.subheadline)
                .foregroundStyle(action.isComplete ? .secondary : .primary)
                .strikethrough(action.isComplete)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(action.isEdited ? Color.accentTeal : Color(.secondaryLabel))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Personal Todo Row

struct WeekTodoRow: View {
    @EnvironmentObject var store: AppStore
    let todo: DailyTodo
    let goalId: UUID
    let weekId: UUID

    var body: some View {
        HStack(spacing: 12) {
            Button {
                guard let gi = store.goals.firstIndex(where: { $0.id == goalId }),
                      let wi = store.goals[gi].weeklyPlans.firstIndex(where: { $0.id == weekId }),
                      let ti = store.goals[gi].weeklyPlans[wi].personalTodos.firstIndex(where: { $0.id == todo.id }) else { return }
                store.goals[gi].weeklyPlans[wi].personalTodos[ti].isComplete.toggle()
                store.updateGoal(store.goals[gi])
            } label: {
                Image(systemName: todo.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(todo.isComplete ? Color.accentTeal : Color(.secondaryLabel))
            }
            .buttonStyle(.plain)

            Text(todo.text)
                .font(.subheadline)
                .foregroundStyle(todo.isComplete ? .secondary : .primary)
                .strikethrough(todo.isComplete)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                guard let gi = store.goals.firstIndex(where: { $0.id == goalId }),
                      let wi = store.goals[gi].weeklyPlans.firstIndex(where: { $0.id == weekId }) else { return }
                store.goals[gi].weeklyPlans[wi].personalTodos.removeAll(where: { $0.id == todo.id })
                store.updateGoal(store.goals[gi])
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        WeekDetailView(
            plan: WeeklyPlan(week: 1, theme: "Foundation", focus: "Build the habit before optimizing it.",
                             actions: [ActionItem(text: "Train 3x this week"), ActionItem(text: "Hit protein goal daily")],
                             checkpoint: "You completed 3 sessions", isUnlocked: true),
            goalId: UUID()
        )
    }
    .environmentObject(AppStore())
}
