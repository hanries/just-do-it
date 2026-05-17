import SwiftUI
import Foundation
import Combine
@MainActor
class AppStore: ObservableObject {
    @Published var profile: UserProfile = UserProfile()
    @Published var goals: [Goal] = []
    @Published var entries: [JournalEntry] = []
    @Published var personalTodos: [PersonalTodo] = []
    @Published var streakCount: Int = 0

    private let profileKey   = "goalos.profile"
    private let goalsKey     = "goalos.goals"
    private let entriesKey   = "goalos.entries"
    private let todosKey     = "goalos.personaltodos"
    private let streakKey    = "goalos.streak"
    private let lastActiveKey = "goalos.lastactive"

    init() {
        load()
        updateStreak()
    }

    // MARK: - Profile

    func saveProfile(_ p: UserProfile) {
        profile = p
        persist()
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

    // MARK: - Milestone completion

    func completeMilestone(goalId: UUID, milestoneId: UUID) {
        guard let gi = goals.firstIndex(where: { $0.id == goalId }),
              let mi = goals[gi].milestones.firstIndex(where: { $0.id == milestoneId }) else { return }
        goals[gi].milestones[mi].isComplete = true
        // Unlock next 2 weeks
        let nextWeek = goals[gi].currentUnlockedWeek + 2
        goals[gi].currentUnlockedWeek = min(nextWeek, goals[gi].timeframeWeeks)
        // Unlock next weekly plan if available
        for wi in goals[gi].weeklyPlans.indices {
            if goals[gi].weeklyPlans[wi].week <= goals[gi].currentUnlockedWeek {
                goals[gi].weeklyPlans[wi].isUnlocked = true
            }
        }
        persist()
    }

    // MARK: - Weekly Plan actions

    func toggleAction(goalId: UUID, weekId: UUID, actionId: UUID) {
        guard let gi = goals.firstIndex(where: { $0.id == goalId }),
              let wi = goals[gi].weeklyPlans.firstIndex(where: { $0.id == weekId }),
              let ai = goals[gi].weeklyPlans[wi].actions.firstIndex(where: { $0.id == actionId }) else { return }
        goals[gi].weeklyPlans[wi].actions[ai].isComplete.toggle()
        persist()
    }

    func editAction(goalId: UUID, weekId: UUID, actionId: UUID, newText: String) {
        guard let gi = goals.firstIndex(where: { $0.id == goalId }),
              let wi = goals[gi].weeklyPlans.firstIndex(where: { $0.id == weekId }),
              let ai = goals[gi].weeklyPlans[wi].actions.firstIndex(where: { $0.id == actionId }) else { return }
        goals[gi].weeklyPlans[wi].actions[ai].text = newText
        goals[gi].weeklyPlans[wi].actions[ai].isEdited = true
        persist()
    }

    func completeWeek(goalId: UUID, weekId: UUID) {
        guard let gi = goals.firstIndex(where: { $0.id == goalId }),
              let wi = goals[gi].weeklyPlans.firstIndex(where: { $0.id == weekId }) else { return }
        goals[gi].weeklyPlans[wi].isComplete = true
        persist()
    }

    // MARK: - Personal Todos

    private var todayKey: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    var todaysPersonalTodos: [PersonalTodo] {
        personalTodos.filter { $0.dateKey == todayKey }
    }

    func addPersonalTodo(text: String) {
        personalTodos.append(PersonalTodo(text: text, dateKey: todayKey))
        persist()
    }

    func togglePersonalTodo(id: UUID) {
        if let idx = personalTodos.firstIndex(where: { $0.id == id }) {
            personalTodos[idx].isComplete.toggle()
            persist()
        }
    }

    func deletePersonalTodo(id: UUID) {
        personalTodos.removeAll(where: { $0.id == id })
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
        updateStreak()
        persist()
    }

    func entryForDate(_ date: Date) -> JournalEntry? {
        entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
    }

    func moodForDate(_ date: Date) -> Mood? {
        entryForDate(date)?.mood
    }

    // MARK: - Streak

    func updateStreak() {
        var streak = 0
        var checking = Calendar.current.startOfDay(for: Date())
        while entries.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: checking) }) {
            streak += 1
            checking = Calendar.current.date(byAdding: .day, value: -1, to: checking)!
        }
        streakCount = streak
    }

    var currentStreak: Int { streakCount }

    // MARK: - Persistence

    private func persist() {
        if let d = try? JSONEncoder().encode(profile) { UserDefaults.standard.set(d, forKey: profileKey) }
        if let d = try? JSONEncoder().encode(goals) { UserDefaults.standard.set(d, forKey: goalsKey) }
        if let d = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(d, forKey: entriesKey) }
        if let d = try? JSONEncoder().encode(personalTodos) { UserDefaults.standard.set(d, forKey: todosKey) }
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: profileKey),
           let v = try? JSONDecoder().decode(UserProfile.self, from: d) { profile = v }
        if let d = UserDefaults.standard.data(forKey: goalsKey),
           let v = try? JSONDecoder().decode([Goal].self, from: d) { goals = v }
        if let d = UserDefaults.standard.data(forKey: entriesKey),
           let v = try? JSONDecoder().decode([JournalEntry].self, from: d) { entries = v }
        if let d = UserDefaults.standard.data(forKey: todosKey),
           let v = try? JSONDecoder().decode([PersonalTodo].self, from: d) { personalTodos = v }
    }
}
