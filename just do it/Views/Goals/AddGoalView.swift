import SwiftUI

struct AddGoalView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var goalText = ""
    @State private var timeframe = 8
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let timeframes = [4, 8, 12, 16, 24]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Build a consistent study habit for calculus finals…", text: $goalText, axis: .vertical)
                        .font(.system(.body, design: .serif))
                        .lineLimit(3...6)
                } header: {
                    Text("Your big goal")
                } footer: {
                    Text("Be specific. Claude will break this into week-by-week milestones.")
                }

                Section("Timeframe") {
                    Picker("Weeks", selection: $timeframe) {
                        ForEach(timeframes, id: \.self) { w in
                            Text("\(w) weeks").tag(w)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isLoading {
                        GoalProgressScreen().tint(Color("AccentTeal"))
                    } else {
                        Button("Analyze") {
                            Task { await analyze() }
                        }
                        .fontWeight(.semibold)
                        .disabled(goalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }

    private func analyze() async {
        isLoading = true
        errorMessage = nil
        do {
            let weeks = try await AIService.shared.breakdownGoal(
                text: goalText.trimmingCharacters(in: .whitespacesAndNewlines),
                weeks: timeframe
            )
            var goal = Goal(text: goalText.trimmingCharacters(in: .whitespacesAndNewlines), timeframeWeeks: timeframe)
            goal.weeks = weeks
            store.addGoal(goal)
            dismiss()
        } catch {
            errorMessage = "Couldn't generate a breakdown. Check your API key and try again."
        }
        isLoading = false
    }
}

#Preview {
    AddGoalView().environmentObject(AppStore())
}
