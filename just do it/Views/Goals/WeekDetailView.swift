import SwiftUI

// MARK: - Week Detail: weekly goal + AI tasks + user todos

struct WeekDetailView: View {
    @EnvironmentObject var store: AppStore
    let week: WeekMilestone
    let weekIndex: Int
    let goalId: UUID

    @State private var newTodoText = ""
    @FocusState private var todoFieldFocused: Bool

    private var liveWeek: WeekMilestone? {
        store.goals.first(where: { $0.id == goalId })?
            .weeks.first(where: { $0.id == week.id })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Weekly goal banner
                VStack(alignment: .leading, spacing: 6) {
                    Text("Week \(weekIndex + 1) goal")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(liveWeek?.goal ?? week.goal)
                        .font(.system(.title3, design: .serif, weight: .regular))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.accentTeal.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.accentTeal.opacity(0.2), lineWidth: 1)
                )

                // AI-suggested tasks
                if !(liveWeek?.tasks ?? week.tasks).isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Suggested focus areas", systemImage: "sparkles")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        VStack(spacing: 0) {
                            ForEach((liveWeek?.tasks ?? week.tasks), id: \.self) { task in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.accentTeal.opacity(0.7))
                                        .padding(.top, 2)
                                    Text(task)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)

                                if task != (liveWeek?.tasks ?? week.tasks).last {
                                    Divider().padding(.leading, 38)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5)
                        )
                    }
                }

                // Daily to-do list
                VStack(alignment: .leading, spacing: 10) {
                    Label("My to-do list", systemImage: "checklist")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    // Add todo input
                    HStack(spacing: 10) {
                        TextField("Add a task…", text: $newTodoText)
                            .font(.subheadline)
                            .focused($todoFieldFocused)
                            .onSubmit { addTodo() }

                        Button(action: addTodo) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(newTodoText.isEmpty ? Color(.tertiaryLabel) : Color.accentTeal)
                        }
                        .disabled(newTodoText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(todoFieldFocused ? Color.accentTeal : Color(.separator).opacity(0.4),
                                          lineWidth: todoFieldFocused ? 1.5 : 0.5)
                    )

                    // Todo items
                    if let todos = liveWeek?.dailyTodos, !todos.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(todos) { todo in
                                TodoRowView(todo: todo, goalId: goalId, weekId: week.id)
                                if todo.id != todos.last?.id {
                                    Divider().padding(.leading, 46)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5)
                        )
                    } else {
                        Text("No tasks yet — add something above")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                }

                // Mark week complete
                if !(liveWeek?.isComplete ?? week.isComplete) {
                    Button {
                        store.markWeekComplete(goalId: goalId, weekId: week.id)
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
        .navigationTitle("Week \(weekIndex + 1)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addTodo() {
        let text = newTodoText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        store.addTodo(goalId: goalId, weekId: week.id, text: text)
        newTodoText = ""
    }
}

// MARK: - Todo Row

struct TodoRowView: View {
    @EnvironmentObject var store: AppStore
    let todo: DailyTodo
    let goalId: UUID
    let weekId: UUID

    var body: some View {
        HStack(spacing: 12) {
            Button {
                store.toggleTodo(goalId: goalId, weekId: weekId, todoId: todo.id)
            } label: {
                Image(systemName: todo.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(todo.isComplete ? Color.accentTeal : Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)

            Text(todo.text)
                .font(.subheadline)
                .foregroundStyle(todo.isComplete ? .secondary : .primary)
                .strikethrough(todo.isComplete)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                store.deleteTodo(goalId: goalId, weekId: weekId, todoId: todo.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
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
            week: WeekMilestone(weekNumber: 1, goal: "Research GT transfer requirements", tasks: ["Review admission page", "Email academic advisor", "List required courses"]),
            weekIndex: 0,
            goalId: UUID()
        )
    }
    .environmentObject(AppStore())
}
