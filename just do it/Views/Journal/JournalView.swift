import SwiftUI

struct JournalView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedMood: Mood?
    @State private var journalText = ""
    @State private var checkedTasks: Set<String> = []

    private var today: Date { Calendar.current.startOfDay(for: Date()) }
    private var existingEntry: JournalEntry? { store.entryForDate(today) }

    private var currentTasks: [(key: String, label: String)] {
        var result: [(key: String, label: String)] = []
        for goal in store.goals {
            guard let week = goal.currentWeek else { continue }
            for (i, task) in week.tasks.prefix(3).enumerated() {
                result.append((key: "\(goal.id)-\(week.id)-\(i)", label: task))
            }
        }
        return Array(result.prefix(6))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Date header
                VStack(alignment: .leading, spacing: 2) {
                    Text(today, format: .dateTime.weekday(.wide))
                        .font(.system(.largeTitle, design: .serif, weight: .regular))
                    Text(today, format: .dateTime.month(.wide).day())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Mood picker
                VStack(alignment: .leading, spacing: 10) {
                    Label("How did today go?", systemImage: "face.smiling")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        ForEach(Mood.allCases, id: \.self) { mood in
                            MoodChip(mood: mood, isSelected: selectedMood == mood) {
                                selectedMood = mood
                            }
                        }
                    }
                }

                // Task checklist (only shown if goals exist)
                if !currentTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("This week's tasks", systemImage: "checklist")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        VStack(spacing: 0) {
                            ForEach(currentTasks, id: \.key) { task in
                                TaskCheckRow(
                                    label: task.label,
                                    isChecked: checkedTasks.contains(task.key)
                                ) {
                                    if checkedTasks.contains(task.key) {
                                        checkedTasks.remove(task.key)
                                    } else {
                                        checkedTasks.insert(task.key)
                                    }
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

                // Journal text
                VStack(alignment: .leading, spacing: 10) {
                    Label("Reflection", systemImage: "text.alignleft")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    TextEditor(text: $journalText)
                        .font(.system(.body, design: .serif))
                        .frame(minHeight: 140)
                        .padding(12)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5)
                        )
                        .overlay(alignment: .topLeading) {
                            if journalText.isEmpty {
                                Text("What did you work on? Any wins, blockers, reflections…")
                                    .font(.system(.body, design: .serif))
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 20)
                                    .padding(.leading, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                // Save button
                Button(action: saveEntry) {
                    Label("Save entry", systemImage: "checkmark")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("AccentTeal"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Past entries
                if !store.entries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Past entries")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        ForEach(store.entries.prefix(5)) { entry in
                            PastEntryRow(entry: entry)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Daily Log")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadExistingEntry)
    }

    private func loadExistingEntry() {
        if let entry = existingEntry {
            selectedMood = entry.mood
            journalText = entry.text
            checkedTasks = entry.completedTaskKeys
        }
    }

    private func saveEntry() {
        var entry = JournalEntry(text: journalText)
        entry.mood = selectedMood
        entry.completedTaskKeys = checkedTasks
        store.saveEntry(entry)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Mood Chip

struct MoodChip: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.title3)
                Text(mood.label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isSelected ? Color(mood.color) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color(mood.color).opacity(0.12) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color(mood.color) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Task Check Row

struct TaskCheckRow: View {
    let label: String
    let isChecked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? Color("AccentTeal") : Color.secondary)


                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(isChecked ? .secondary : .primary)
                    .strikethrough(isChecked)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        Divider().padding(.leading, 50)
    }
}

// MARK: - Past Entry Row

struct PastEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let mood = entry.mood {
                    Text(mood.emoji + " " + mood.label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(mood.color))
                }
                Spacer()
                Text(entry.date, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            if !entry.text.isEmpty {
                Text(entry.text)
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5)
        )
    }
}

#Preview {
    NavigationStack { JournalView() }
        .environmentObject(AppStore())
}
