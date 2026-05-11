import Foundation

// MARK: - Goal

struct Goal: Identifiable, Codable {
    var id: UUID = UUID()
    var text: String
    var timeframeWeeks: Int
    var createdAt: Date = Date()
    var weeks: [WeekMilestone] = []

    var completedWeeks: Int { weeks.filter(\.isComplete).count }
    var progressFraction: Double {
        guard !weeks.isEmpty else { return 0 }
        return Double(completedWeeks) / Double(weeks.count)
    }
    var currentWeek: WeekMilestone? { weeks.first(where: { !$0.isComplete }) }
}

struct WeekMilestone: Identifiable, Codable {
    var id: UUID = UUID()
    var weekNumber: Int
    var goal: String           // short milestone summary
    var tasks: [String] = []   // concrete daily tasks
    var isComplete: Bool = false
}

// MARK: - Journal Entry

struct JournalEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var mood: Mood?
    var text: String
    var completedTaskKeys: Set<String> = []   // "goalId-weekId-taskIndex"

    var dateKey: String {
        Calendar.current.startOfDay(for: date).ISO8601Format()
    }
}

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
