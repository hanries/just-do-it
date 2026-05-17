import Foundation

// MARK: - Response types matching the new prompt schema

struct AIGoalResponse: Codable {
    struct Milestone: Codable {
        let milestoneNumber: Int
        let title: String
        let description: String
        let dueWeek: Int
        enum CodingKeys: String, CodingKey {
            case milestoneNumber = "milestone_number"
            case title, description
            case dueWeek = "due_week"
        }
    }
    struct WeeklyPlan: Codable {
        let week: Int
        let theme: String
        let focus: String
        let actions: [String]
        let checkpoint: String
    }
    let goalSummary: String
    let milestones: [Milestone]
    let weeklyPlans: [WeeklyPlan]
    enum CodingKeys: String, CodingKey {
        case goalSummary = "goal_summary"
        case milestones
        case weeklyPlans = "weekly_plans"
    }
}

enum AIServiceError: Error {
    case networkError(Error)
    case decodingError
    case emptyResponse
}

class AIService {
    static let shared = AIService()
    private init() {}

    private let apiKey = "YOUR_API_KEY_HERE"
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    private let systemPrompt = """
    You are a goal planning assistant inside a habit-building app. Your job is to take a user's long-term goal and break it into realistic milestones and weekly action plans — personalized to their situation.
    Rules:
    - Only output valid JSON. No preamble, no explanation, no markdown fences.
    - Generate 3-5 milestones spread across the full timeline. Milestones should feel like meaningful checkpoints, not just task lists.
    - Generate weekly plans for the first 2 weeks only. Future weeks stay locked until the user progresses.
    - Each week should have 2-4 actions max. Never overwhelm — the user has limited hours.
    - Actions must be specific and time-aware. If the user has 3 hours/week, no single action should imply more than 1.5 hours.
    - Account for the user's stated obstacle.
    - Milestones should be framed as destinations ("By now you can X"), not tasks ("Do X").
    - Never use generic filler like "stay consistent" or "keep going" as actions.
    """

    func breakdownGoal(goal: String, timelineWeeks: Int, obstacle: String, hoursPerWeek: Double) async throws -> AIGoalResponse {
        let userMessage = """
        Goal: \(goal)
        Timeline: \(timelineWeeks) weeks
        Biggest obstacle: \(obstacle)
        Hours per week available: \(hoursPerWeek)

        Output JSON with this exact structure:
        {
          "goal_summary": "motivating one-sentence reframe",
          "milestones": [{"milestone_number":1,"title":"...","description":"By now you can...","due_week":3}],
          "weekly_plans": [{"week":1,"theme":"Foundation","focus":"...","actions":["..."],"checkpoint":"..."}]
        }
        """

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1500,
            "system": systemPrompt,
            "messages": [["role": "user", "content": userMessage]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        struct Envelope: Codable {
            struct Content: Codable { let text: String }
            let content: [Content]
        }
        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
              let rawText = envelope.content.first?.text,
              let jsonData = rawText.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(AIGoalResponse.self, from: jsonData)
        else { throw AIServiceError.decodingError }

        return parsed
    }

    // MARK: - Mock for testing

    func breakdownGoalMock(goal: String, timelineWeeks: Int, obstacle: String, hoursPerWeek: Double) async throws -> AIGoalResponse {
        try await Task.sleep(nanoseconds: 1_500_000_000)

        // Hardcoded mock for "gain 10 lbs of muscle in 10 weeks"
        return AIGoalResponse(
            goalSummary: "Build 10 lbs of lean muscle in 10 weeks through consistent training and smart eating — no fluff, just results.",
            milestones: [
                .init(milestoneNumber: 1, title: "Foundation Built", description: "By now you have a consistent 4-day training schedule and are hitting your protein target daily.", dueWeek: 2),
                .init(milestoneNumber: 2, title: "Progressive Overload Locked In", description: "By now you're adding weight every session and your main lifts have each gone up by at least 10 lbs.", dueWeek: 5),
                .init(milestoneNumber: 3, title: "Halfway There", description: "By now you've gained 4-5 lbs and your clothes fit noticeably different.", dueWeek: 7),
                .init(milestoneNumber: 4, title: "Final Push", description: "By now you're training at high intensity and within reach of your 10 lb goal.", dueWeek: 9),
                .init(milestoneNumber: 5, title: "Goal Achieved", description: "By now you've gained 10 lbs of muscle and have a sustainable routine to keep going.", dueWeek: 10)
            ],
            weeklyPlans: [
                .init(week: 1, theme: "Foundation", focus: "Set up the system so success is automatic, not willpower-dependent.",
                      actions: [
                        "Calculate your daily calorie target (bodyweight x 16) and add it to your phone notes",
                        "Schedule 4 training days in your calendar this week — treat them like appointments",
                        "Do your first session: 3x8 squat, bench, deadlift at a comfortable weight"
                      ],
                      checkpoint: "You completed at least 3 of 4 planned sessions and know your daily calorie target."),
                .init(week: 2, theme: "Momentum", focus: "Establish the habit loop before worrying about perfection.",
                      actions: [
                        "Increase each lift by 5 lbs from last week",
                        "Prep one high-protein meal in bulk (e.g. ground beef + rice) to cover 3 days",
                        "Weigh yourself each morning and log it — just observe, no judgment"
                      ],
                      checkpoint: "You hit all 4 sessions and your average daily protein was above 140g.")
            ]
        )
    }
}
