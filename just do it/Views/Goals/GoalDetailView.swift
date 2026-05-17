import SwiftUI

struct GoalDetailView: View {
    @EnvironmentObject var store: AppStore
    let goal: Goal

    private var liveGoal: Goal {
        store.goals.first(where: { $0.id == goal.id }) ?? goal
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Goal summary card
                if !liveGoal.goalSummary.isEmpty {
                    Text(liveGoal.goalSummary)
                        .font(.system(.title3, design: .serif, weight: .regular))
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentTeal.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.accentTeal.opacity(0.2), lineWidth: 1))
                }

                // Milestones
                VStack(alignment: .leading, spacing: 10) {
                    Text("Milestones")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    ForEach(liveGoal.milestones) { milestone in
                        MilestoneCard(milestone: milestone, goalId: liveGoal.id)
                    }
                }

                // Weekly Plans
                VStack(alignment: .leading, spacing: 10) {
                    Text("Weekly Plans")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    ForEach(liveGoal.weeklyPlans) { plan in
                        if plan.isUnlocked {
                            NavigationLink(destination: WeekDetailView(plan: plan, goalId: liveGoal.id)) {
                                WeekPlanRow(plan: plan)
                            }
                            .buttonStyle(.plain)
                        } else {
                            LockedWeekRow(week: plan.week)
                        }
                    }

                    // Show locked future weeks
                    let plannedWeeks = Set(liveGoal.weeklyPlans.map(\.week))
                    let unlockedUpTo = liveGoal.currentUnlockedWeek
                    ForEach(Array(stride(from: unlockedUpTo + 1, through: liveGoal.timeframeWeeks, by: 2)), id: \.self) { w in
                        if !plannedWeeks.contains(w) {
                            LockedWeekRow(week: w)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle(liveGoal.text.prefix(20) + "…")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Milestone Card

struct MilestoneCard: View {
    @EnvironmentObject var store: AppStore
    let milestone: Milestone
    let goalId: UUID

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(milestone.isComplete ? Color.accentTeal : Color(.secondarySystemBackground))
                    .frame(width: 36, height: 36)
                if milestone.isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(milestone.milestoneNumber)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(milestone.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(milestone.isComplete ? .secondary : .primary)
                    Spacer()
                    Text("Wk \(milestone.dueWeek)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(milestone.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if !milestone.isComplete {
                Button {
                    store.completeMilestone(goalId: goalId, milestoneId: milestone.id)
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.title3)
                        .foregroundStyle(Color.accentTeal)
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .strokeBorder(milestone.isComplete ? Color.accentTeal.opacity(0.3) : Color(.separator).opacity(0.4),
                          lineWidth: milestone.isComplete ? 1 : 0.5))
    }
}

// MARK: - Week Plan Row

struct WeekPlanRow: View {
    let plan: WeeklyPlan

    var doneCount: Int { plan.actions.filter(\.isComplete).count }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Week \(plan.week)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(plan.theme)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.accentTeal)
                }
                Text(plan.focus)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text("\(doneCount)/\(plan.actions.count) actions done")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: plan.isComplete ? "checkmark.circle.fill" : "chevron.right")
                .foregroundStyle(plan.isComplete ? Color.accentTeal : .secondary)
                .font(.subheadline)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5))
    }
}

// MARK: - Locked Week Row

struct LockedWeekRow: View {
    let week: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Week \(week) — unlocks after completing previous milestone")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack { GoalDetailView(goal: Goal(text: "Sample goal", timeframeWeeks: 10)) }
        .environmentObject(AppStore())
}
