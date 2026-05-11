import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingAddGoal = false

    var body: some View {
        Group {
            if store.goals.isEmpty {
                GoalsEmptyState()
            } else {
                List {
                    ForEach(store.goals) { goal in
                        NavigationLink(destination: GoalDetailView(goal: goal)) {
                            GoalRowView(goal: goal)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .onDelete(perform: store.deleteGoal)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddGoal = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView()
        }
    }
}

// MARK: - Goal Row

struct GoalRowView: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.text)
                        .font(.system(.body, design: .serif, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text("\(goal.timeframeWeeks) weeks · Week \(goal.completedWeeks + 1) of \(goal.weeks.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                CircularProgressView(fraction: goal.progressFraction)
                    .frame(width: 40, height: 40)
            }

            if let current = goal.currentWeek {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color("AccentTeal"))
                        .frame(width: 3, height: 30)
                    Text(current.goal)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
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

// MARK: - Empty State

struct GoalsEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "scope")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No goals yet")
                .font(.headline)
            Text("Tap + to add your first big goal.\nClaude will break it into weekly milestones.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

#Preview {
    NavigationStack { GoalsView() }
        .environmentObject(AppStore())
}
