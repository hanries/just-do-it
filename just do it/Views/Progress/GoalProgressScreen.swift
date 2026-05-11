import SwiftUI

struct GoalProgressScreen: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Stats row
                HStack(spacing: 12) {
                    StatCard(value: "\(store.currentStreak)", label: "Day streak", icon: "flame")
                    StatCard(value: "\(store.entries.count)", label: "Entries", icon: "text.book.closed")
                    StatCard(value: "\(store.goals.count)", label: "Goals", icon: "scope")
                }

                // Calendar
                VStack(alignment: .leading, spacing: 12) {
                    Text("This month")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    MoodCalendarView()
                }

                // Goal progress bars
                if !store.goals.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Goal progress")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        VStack(spacing: 0) {
                            ForEach(store.goals) { goal in
                                GoalProgressRow(goal: goal)
                                if goal.id != store.goals.last?.id {
                                    Divider().padding(.leading, 16)
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

                // Mood legend
                VStack(alignment: .leading, spacing: 10) {
                    Text("Mood key")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        ForEach(Mood.allCases, id: \.self) { mood in
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(Color(mood.color))
                                    .frame(width: 8, height: 8)
                                Text(mood.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color("AccentTeal"))
            Text(value)
                .font(.system(.title, design: .serif, weight: .regular))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Mood Calendar

struct MoodCalendarView: View {
    @EnvironmentObject var store: AppStore

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
    private let dayLabels = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    private var calendarDays: [(day: Int?, date: Date?, mood: Mood?)] {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let firstOfMonth = cal.date(from: comps) else { return [] }

        let firstWeekday = cal.component(.weekday, from: firstOfMonth) - 1
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30

        var days: [(day: Int?, date: Date?, mood: Mood?)] = Array(repeating: (nil, nil, nil), count: firstWeekday)
        for d in 1...daysInMonth {
            let date = cal.date(bySetting: .day, value: d, of: firstOfMonth)
            let mood = date.flatMap { store.moodForDate($0) }
            days.append((day: d, date: date, mood: mood))
        }
        return days
    }

    var body: some View {
        VStack(spacing: 5) {
            // Day labels
            HStack(spacing: 5) {
                ForEach(dayLabels, id: \.self) { d in
                    Text(d)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(Array(calendarDays.enumerated()), id: \.offset) { _, item in
                    if let day = item.day {
                        CalendarDayCell(day: day, date: item.date, mood: item.mood)
                    } else {
                        Color.clear.aspectRatio(1, contentMode: .fill)
                    }
                }
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

struct CalendarDayCell: View {
    let day: Int
    let date: Date?
    let mood: Mood?

    private var isToday: Bool {
        guard let date else { return false }
        return Calendar.current.isDateInToday(date)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(mood != nil ? Color(mood!.color).opacity(0.25) : Color(.tertiarySystemBackground))

            if isToday {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.primary.opacity(0.6), lineWidth: 1.5)
            }

            Text("\(day)")
                .font(.system(size: 11, weight: isToday ? .semibold : .regular))
                .foregroundStyle(mood != nil ? Color(mood!.color) : (isToday ? Color.primary : Color.secondary))
        }
        .aspectRatio(1, contentMode: .fill)
    }
}

// MARK: - Goal Progress Row

struct GoalProgressRow: View {
    let goal: Goal

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.text)
                    .font(.subheadline)
                    .lineLimit(1)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.tertiarySystemBackground)).frame(height: 4)
                        Capsule()
                            .fill(Color("AccentTeal"))
                            .frame(width: geo.size.width * goal.progressFraction, height: 4)
                    }
                }
                .frame(height: 4)
            }

            Text("\(Int(goal.progressFraction * 100))%")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color("AccentTeal"))
                .frame(width: 38, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    NavigationStack { GoalProgressScreen() }
        .environmentObject(AppStore())
}
