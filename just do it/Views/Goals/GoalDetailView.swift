import SwiftUI

struct GoalDetailView: View {
    @EnvironmentObject var store: AppStore
    let goal: Goal

    private var liveGoal: Goal {
        store.goals.first(where: { $0.id == goal.id }) ?? goal
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Header card
                VStack(alignment: .leading, spacing: 8) {
                    Text(liveGoal.text)
                        .font(.system(.title2, design: .serif, weight: .regular))

                    HStack {
                        Label("\(liveGoal.completedWeeks) of \(liveGoal.weeks.count) weeks done",
                              systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(Int(liveGoal.progressFraction * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AccentTeal"))
                    }

                    ProgressView(value: liveGoal.progressFraction)
                        .tint(Color("AccentTeal"))
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Weekly milestones
                Text("Weekly milestones")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                ForEach(Array(liveGoal.weeks.enumerated()), id: \.element.id) { index, week in
                    WeekCardView(week: week, weekIndex: index, goalId: liveGoal.id)
                }
            }
            .padding(16)
        }
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Week Card

struct WeekCardView: View {
    @EnvironmentObject var store: AppStore
    let week: WeekMilestone
    let weekIndex: Int
    let goalId: UUID

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(week.isComplete ? Color("AccentTeal") : Color(.tertiarySystemBackground))
                            .frame(width: 28, height: 28)
                        if week.isComplete {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(weekIndex + 1)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Week \(weekIndex + 1)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(week.goal)
                            .font(.subheadline)
                            .foregroundStyle(week.isComplete ? .secondary : .primary)
                            .strikethrough(week.isComplete)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            // Expanded tasks
            if expanded {
                Divider().padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(week.tasks, id: \.self) { task in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color("AccentTeal").opacity(0.4))
                                .frame(width: 5, height: 5)
                                .padding(.top, 6)
                            Text(task)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !week.isComplete {
                        Button {
                            store.markWeekComplete(goalId: goalId, weekId: week.id)
                        } label: {
                            Label("Mark week complete", systemImage: "checkmark.circle.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color("AccentTeal"))
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    week.isComplete ? Color("AccentTeal").opacity(0.3) : Color(.separator).opacity(0.4),
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
