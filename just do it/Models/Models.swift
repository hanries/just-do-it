import Foundation

// MARK: - Onboarding Profile

struct UserProfile: Codable {
    var hasCompletedOnboarding: Bool = false
    var currentSituation: String = ""
    var biggestObstacle: String = ""
    var hoursPerWeek: Double = 3.0
}

// MARK: - Goal

struct Goal: Identifiable, Codable {
    var id: UUID = UUID()
    var text: String
    var goalSummary: String = ""        // AI reframe
    var timeframeWeeks: Int
    var createdAt: Date = Date()
    var milestones: [Milestone] = []
    var weeklyPlans: [WeeklyPlan] = []
    var currentUnlockedWeek: Int = 1    // only show up to this week

    var currentMilestone: Milestone? {
        milestones.first(where: { !$0.isComplete })
    }
    var progressFraction: Double {
        guard !milestones.isEmpty else { return 0 }
        let done = milestones.filter(\.isComplete).count
        return Double(done) / Double(milestones.count)
    }
}

// MARK: - Milestone (meaningful checkpoint)

struct Milestone: Identifiable, Codable {
    var id: UUID = UUID()
    var milestoneNumber: Int
    var title: String
    var description: String             // "By now you can X"
    var dueWeek: Int
    var isComplete: Bool = false
}

// MARK: - Weekly Plan

struct WeeklyPlan: Identifiable, Codable {
    var id: UUID = UUID()
    var week: Int
    var theme: String                   // e.g. "Foundation"
    var focus: String                   // one sentence
    var actions: [ActionItem]
    var checkpoint: String              // how the user knows they succeeded
    var isUnlocked: Bool = false
    var isComplete: Bool = false

    // User-created personal todos on top of AI actions
    var personalTodos: [DailyTodo] = []
}

// MARK: - Action Item (AI-generated, user-editable)

struct ActionItem: Identifiable, Codable {
    var id: UUID = UUID()
    var text: String
    var isComplete: Bool = false
    var isEdited: Bool = false          // track if user modified it
}

// MARK: - Daily Todo (user-created)

struct DailyTodo: Identifiable, Codable {
    var id: UUID = UUID()
    var text: String
    var isComplete: Bool = false
    var createdAt: Date = Date()
}

// MARK: - Personal Todo (Daily Log, resets daily)

struct PersonalTodo: Identifiable, Codable {
    var id: UUID = UUID()
    var text: String
    var isComplete: Bool = false
    var dateKey: String
}

// MARK: - Journal Entry

struct JournalEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var mood: Mood?
    var text: String
    var completedTaskKeys: Set<String> = []

    var dateKey: String {
        Calendar.current.startOfDay(for: date).ISO8601Format()
    }
}

// MARK: - Mood

enum Mood: String, Codable, CaseIterable {
    case great, good, okay, rough

    var label: String {
        switch self {
        case .great: return "Great"
        case .good:  return "Good"
        case .okay:  return "Okay"
        case .rough: return "Rough"
        }
    }
    var emoji: String {
        switch self {
        case .great: return "🌱"
        case .good:  return "✨"
        case .okay:  return "〰️"
        case .rough: return "🌧"
        }
    }
    var color: String {
        switch self {
        case .great: return "MoodTeal"
        case .good:  return "MoodPurple"
        case .okay:  return "MoodAmber"
        case .rough: return "MoodCoral"
        }
    }
}
