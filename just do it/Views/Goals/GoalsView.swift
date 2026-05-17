import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ZStack(alignment: .bottom) {
            if store.goals.isEmpty {
                GoalsEmptyState()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Streak banner
                        if store.currentStreak > 0 {
                            StreakBanner(streak: store.currentStreak)
                        }

                        ForEach(store.goals) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                GoalCardView(goal: goal)
                            }
                            .buttonStyle(.plain)
                        }

                        Color.clear.frame(height: 90)
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Streak Banner

struct StreakBanner: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("🔥")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) day streak")
                    .font(.subheadline.weight(.semibold))
                Text("Keep logging daily to maintain it")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.accentTeal.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.accentTeal.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Goal Card

struct GoalCardView: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Goal summary (AI reframe)
            if !goal.goalSummary.isEmpty {
                Text(goal.goalSummary)
                    .font(.system(.body, design: .serif, weight: .regular))
                    .foregroundStyle(.primary)
            } else {
                Text(goal.text)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Milestones")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(goal.milestones.filter(\.isComplete).count)/\(goal.milestones.count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.accentTeal)
                }
                ProgressView(value: goal.progressFraction)
                    .tint(Color.accentTeal)
            }

            // Current milestone
            if let current = goal.currentMilestone {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.accentTeal)
                        .frame(width: 6, height: 6)
                    Text("Next: \(current.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Week \(current.dueWeek)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct GoalsEmptyState: View {
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "scope")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("No goals yet")
                    .font(.headline)
                Text("Your plan will appear here after onboarding.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    NavigationStack { GoalsView() }
        .environmentObject(AppStore())
}
