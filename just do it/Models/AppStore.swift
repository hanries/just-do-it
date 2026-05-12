import SwiftUI
import Foundation
import Combine

@MainActor
class AppStore: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var entries: [JournalEntry] = []

    private let goalsKey = "goalos.goals"
    private let entriesKey = "goalos.entries"

    init() { load() }

    // MARK: - Goals

    func addGoal(_ goal: Goal) {
        goals.insert(goal, at: 0)
        persist()
    }

    func updateGoal(_ goal: Goal) {
        if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[idx] = goal
            persist()
        }
    }

    func deleteGoal(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
        persist()
    }

    func markWeekComplete(goalId: UUID, weekId: UUID) {
        guard let gi = goals.firstIndex(where: { $0.id == goalId }),
              let wi = goals[gi].weeks.firstIndex(where: { $0.id == weekId }) else { return }
        goals[gi].weeks[wi].isComplete = true
        persist()
    }

    // MARK: - Daily Todos

    func addTodo(goalId: UUID, weekId: UUID, text: String) {
        guard let gi = goals.firstIndex(where: { $0.id == goalId }),
              let wi = goals[gi].weeks.firstIndex(where: { $0.id == weekId }) else { return }
        let todo = DailyTodo(text: text)
        goals[gi].weeks[wi].dailyTodos.append(todo)
        persist()
    }

    func toggleTodo(goalId: UUID, weekId: UUID, todoId: UUID) {
        guard let gi = goals.firstIndex(where: { $0.id == goalId }),
              let wi = goals[gi].weeks.firstIndex(where: { $0.id == weekId }),
              let ti = goals[gi].weeks[wi].dailyTodos.firstIndex(where: { $0.id == todoId }) else { return }
        goals[gi].weeks[wi].dailyTodos[ti].isComplete.toggle()
        persist()
    }

    func deleteTodo(goalId: UUID, weekId: UUID, todoId: UUID) {
        guard let gi = goals.firstIndex(where: { $0.id == goalId }),
              let wi = goals[gi].weeks.firstIndex(where: { $0.id == weekId }) else { return }
        goals[gi].weeks[wi].dailyTodos.removeAll(where: { $0.id == todoId })
        persist()
    }

    // MARK: - Journal

    func saveEntry(_ entry: JournalEntry) {
        let cal = Calendar.current
        if let idx = entries.firstIndex(where: { cal.isDate($0.date, inSameDayAs: entry.date) }) {
            entries[idx] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        persist()
    }

    func entryForDate(_ date: Date) -> JournalEntry? {
        entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
    }

    func moodForDate(_ date: Date) -> Mood? {
        entryForDate(date)?.mood
    }

    // MARK: - Stats

    var currentStreak: Int {
        var streak = 0
        var checking = Calendar.current.startOfDay(for: Date())
        while entries.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: checking) }) {
            streak += 1
            checking = Calendar.current.date(byAdding: .day, value: -1, to: checking)!
        }
        return streak
    }

    // MARK: - Persistence

    private func persist() {
        if let d = try? JSONEncoder().encode(goals) { UserDefaults.standard.set(d, forKey: goalsKey) }
        if let d = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(d, forKey: entriesKey) }
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: goalsKey),
           let v = try? JSONDecoder().decode([Goal].self, from: d) { goals = v }
        if let d = UserDefaults.standard.data(forKey: entriesKey),
           let v = try? JSONDecoder().decode([JournalEntry].self, from: d) { entries = v }
    }
}
