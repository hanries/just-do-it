import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    @State private var currentPage = 0

    @State private var goalText = ""
    @State private var timeframeWeeks = 8
    @State private var currentSituation = ""
    @State private var biggestObstacle = ""
    @State private var hoursPerWeek: Double = 3.0
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let timeframes = [4, 6, 8, 10, 12, 16, 24]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<5) { i in
                        Capsule()
                            .fill(i <= currentPage ? Color.accentTeal : Color(.tertiarySystemFill))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.25), value: currentPage)
                    }
                }
                .padding(.top, 56)
                .padding(.bottom, 20)

                // Pages
                TabView(selection: $currentPage) {
                    GoalPage(goalText: $goalText, timeframeWeeks: $timeframeWeeks, timeframes: timeframes)
                        .tag(0)
                    SituationPage(currentSituation: $currentSituation)
                        .tag(1)
                    ObstaclePage(biggestObstacle: $biggestObstacle)
                        .tag(2)
                    CommitmentPage(hoursPerWeek: $hoursPerWeek)
                        .tag(3)
                    SummaryPage(
                        goalText: goalText,
                        timeframeWeeks: timeframeWeeks,
                        currentSituation: currentSituation,
                        biggestObstacle: biggestObstacle,
                        hoursPerWeek: hoursPerWeek,
                        isLoading: isLoading,
                        errorMessage: errorMessage
                    )
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                .frame(maxHeight: .infinity)

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button {
                            withAnimation { currentPage -= 1 }
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.accentTeal)
                                .frame(width: 50, height: 50)
                                .background(Color.accentTeal.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }

                    Spacer()

                    if currentPage < 4 {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            HStack(spacing: 8) {
                                Text("Next")
                                Image(systemName: "arrow.right")
                            }
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(canAdvance ? Color.accentTeal : Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                        }
                        .disabled(!canAdvance)
                    } else {
                        Button {
                            Task { await buildPlan() }
                        } label: {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Build My Plan")
                                    Image(systemName: "sparkles")
                                }
                            }
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color.accentTeal)
                            .clipShape(Capsule())
                        }
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private var canAdvance: Bool {
        switch currentPage {
        case 0: return !goalText.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return !currentSituation.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !biggestObstacle.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }

    private func buildPlan() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await AIService.shared.breakdownGoalMock(
                goal: goalText,
                timelineWeeks: timeframeWeeks,
                obstacle: biggestObstacle,
                hoursPerWeek: hoursPerWeek
            )

            var goal = Goal(text: goalText, goalSummary: response.goalSummary, timeframeWeeks: timeframeWeeks)

            goal.milestones = response.milestones.map { m in
                Milestone(milestoneNumber: m.milestoneNumber, title: m.title,
                          description: m.description, dueWeek: m.dueWeek)
            }

            goal.weeklyPlans = response.weeklyPlans.map { w in
                WeeklyPlan(
                    week: w.week, theme: w.theme, focus: w.focus,
                    actions: w.actions.map { ActionItem(text: $0) },
                    checkpoint: w.checkpoint,
                    isUnlocked: true
                )
            }

            goal.currentUnlockedWeek = 2

            var profile = store.profile
            profile.hasCompletedOnboarding = true
            profile.currentSituation = currentSituation
            profile.biggestObstacle = biggestObstacle
            profile.hoursPerWeek = hoursPerWeek

            store.addGoal(goal)
            store.saveProfile(profile)
        } catch {
            errorMessage = "Couldn't build your plan. Try again."
        }
        isLoading = false
    }
}

// MARK: - Page 1: Goal + Timeline

struct GoalPage: View {
    @Binding var goalText: String
    @Binding var timeframeWeeks: Int
    let timeframes: [Int]
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's your goal?")
                        .font(.system(.title, design: .serif, weight: .regular))
                    Text("Be specific. The clearer you are, the better your plan.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    TextField("e.g. Gain 10 lbs of muscle in 10 weeks…", text: $goalText, axis: .vertical)
                        .font(.system(.body, design: .serif))
                        .lineLimit(3...5)
                        .focused($focused)
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    Text("Timeline")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(timeframes, id: \.self) { w in
                                Button {
                                    timeframeWeeks = w
                                } label: {
                                    Text("\(w)w")
                                        .font(.subheadline.weight(.medium))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(timeframeWeeks == w ? Color.accentTeal : Color(.secondarySystemBackground))
                                        .foregroundStyle(timeframeWeeks == w ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { focused = true }
    }
}

// MARK: - Page 2: Current Situation

struct SituationPage: View {
    @Binding var currentSituation: String
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Where are you starting from?")
                        .font(.system(.title, design: .serif, weight: .regular))
                    Text("Tell us about your current situation so we can personalize your plan.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                TextField("e.g. I've never trained consistently before, I'm a beginner…", text: $currentSituation, axis: .vertical)
                    .font(.system(.body, design: .serif))
                    .lineLimit(4...6)
                    .focused($focused)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { focused = true }
    }
}

// MARK: - Page 3: Biggest Obstacle

struct ObstaclePage: View {
    @Binding var biggestObstacle: String
    @FocusState private var focused: Bool

    let examples = ["No time", "Lack of motivation", "Not sure where to start", "Past failures"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's your biggest obstacle?")
                        .font(.system(.title, design: .serif, weight: .regular))
                    Text("Be honest. We'll build your plan around it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    FlowLayout(spacing: 8) {
                        ForEach(examples, id: \.self) { ex in
                            Button {
                                biggestObstacle = ex
                            } label: {
                                Text(ex)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(biggestObstacle == ex ? Color.accentTeal.opacity(0.15) : Color(.secondarySystemBackground))
                                    .foregroundStyle(biggestObstacle == ex ? Color.accentTeal : .primary)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().strokeBorder(biggestObstacle == ex ? Color.accentTeal : Color.clear, lineWidth: 1.5))
                            }
                        }
                    }

                    TextField("Or describe your own…", text: $biggestObstacle, axis: .vertical)
                        .font(.system(.body, design: .serif))
                        .lineLimit(2...4)
                        .focused($focused)
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Page 4: Time Commitment

struct CommitmentPage: View {
    @Binding var hoursPerWeek: Double

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How many hours per week can you commit?")
                        .font(.system(.title, design: .serif, weight: .regular))
                    Text("Be realistic — we'll keep your plan within this budget.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 20) {
                    Text(String(format: "%.1f", hoursPerWeek) + " hrs / week")
                        .font(.system(size: 44, design: .serif))
                        .foregroundStyle(Color.accentTeal)
                        .frame(maxWidth: .infinity)

                    Slider(value: $hoursPerWeek, in: 1...20, step: 0.5)
                        .tint(Color.accentTeal)

                    HStack {
                        Text("1 hr").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("20 hrs").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Page 5: Summary

struct SummaryPage: View {
    let goalText: String
    let timeframeWeeks: Int
    let currentSituation: String
    let biggestObstacle: String
    let hoursPerWeek: Double
    let isLoading: Bool
    let errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ready to build your plan")
                        .font(.system(.title, design: .serif, weight: .regular))
                    Text("Here's what we'll personalize for you:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    SummaryRow(icon: "scope", label: "Goal", value: goalText)
                    SummaryRow(icon: "calendar", label: "Timeline", value: "\(timeframeWeeks) weeks")
                    SummaryRow(icon: "person", label: "Starting point", value: currentSituation)
                    SummaryRow(icon: "exclamationmark.triangle", label: "Obstacle", value: biggestObstacle)
                    SummaryRow(icon: "clock", label: "Weekly commitment", value: String(format: "%.1f", hoursPerWeek) + " hrs/week")
                }

                if let error = errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Summary Row

struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.accentTeal)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline).lineLimit(2)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }.reduce(0, +)
            + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var currentWidth: CGFloat = 0
        let maxWidth = proposal.width ?? 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(view)
            currentWidth += size.width + spacing
        }
        return rows
    }
}
