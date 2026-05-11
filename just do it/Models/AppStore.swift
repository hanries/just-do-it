import Foundation
import Combine
import SwiftUI

@MainActor
class AppStore: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var entries: [JournalEntry] = []

    private let goalsKey = "goalos.goals"
    private let entriesKey = "goalos.entries"

    init() {
        load()
    }

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

    // MARK: - Journal

    func saveEntry(_ entry: JournalEntry) {
        // Replace if same day exists
        let cal = Calendar.current
        if let idx = entries.firstIndex(where: {
            cal.isDate($0.date, inSameDayAs: entry.date)
        }) {
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

    // MARK: - Progress stats

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
        if let gData = try? JSONEncoder().encode(goals) { UserDefaults.standard.set(gData, forKey: goalsKey) }
        if let eData = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(eData, forKey: entriesKey) }
    }

    private func load() {
        if let gData = UserDefaults.standard.data(forKey: goalsKey),
           let decoded = try? JSONDecoder().decode([Goal].self, from: gData) {
            goals = decoded
        }
        if let eData = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([JournalEntry].self, from: eData) {
            entries = decoded
        }
    }
}
