import SwiftUI

// MARK: - Goal Detail (stages overview)

struct GoalDetailView: View {
    @EnvironmentObject var store: AppStore
    let goal: Goal

    private var liveGoal: Goal {
        store.goals.first(where: { $0.id == goal.id }) ?? goal
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Header progress card
                VStack(alignment: .leading, spacing: 10) {
                    Text(liveGoal.text)
                        .font(.system(.title2, design: .serif, weight: .regular))

                    HStack {
                        Label("\(liveGoal.completedWeeks) of \(liveGoal.weeks.count) stages done",
                              systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(liveGoal.progressFraction * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentTeal)
                    }

                    ProgressView(value: liveGoal.progressFraction)
                        .tint(Color.accentTeal)
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Stages
                Text("Stages")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                ForEach(Array(liveGoal.weeks.enumerated()), id: \.element.id) { index, week in
                    NavigationLink(destination: WeekDetailView(week: week, weekIndex: index, goalId: liveGoal.id)) {
                        StageRowView(week: week, weekIndex: index)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Stage Row (tappable card leading to WeekDetailView)

struct StageRowView: View {
    let week: WeekMilestone
    let weekIndex: Int

    var todosDone: Int { week.dailyTodos.filter(\.isComplete).count }
    var todosTotal: Int { week.dailyTodos.count }

    var body: some View {
        HStack(spacing: 14) {
            // Stage number / checkmark
            ZStack {
                Circle()
                    .fill(week.isComplete ? Color.accentTeal : Color(.tertiarySystemBackground))
                    .frame(width: 36, height: 36)
                if week.isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(weekIndex + 1)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Week \(weekIndex + 1)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(week.goal)
                    .font(.subheadline)
                    .foregroundStyle(week.isComplete ? .secondary : .primary)
                    .strikethrough(week.isComplete)
                    .multilineTextAlignment(.leading)

                if todosTotal > 0 {
                    Text("\(todosDone)/\(todosTotal) todos done")
                        .font(.caption2)
                        .foregroundStyle(Color.accentTeal)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    week.isComplete ? Color.accentTeal.opacity(0.3) : Color(.separator).opacity(0.4),
                    lineWidth: week.isComplete ? 1 : 0.5
                )
        )
    }
}

#Preview {
    NavigationStack {
        GoalDetailView(goal: Goal(text: "Get into Georgia Tech transfer program", timeframeWeeks: 8))
    }
    .environmentObject(AppStore())
}
