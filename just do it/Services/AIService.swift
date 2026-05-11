import Foundation

// MARK: - AI Goal Breakdown Service
// Wire up to your preferred LLM backend (OpenAI, Anthropic, etc.)

struct WeekBreakdownResponse: Codable {
    struct Week: Codable {
        let week: Int
        let goal: String
        let tasks: [String]
    }
    let weeks: [Week]
}

enum AIServiceError: Error {
    case networkError(Error)
    case decodingError
    case emptyResponse
}

class AIService {
    static let shared = AIService()
    private init() {}

    // MARK: - Replace with your actual API key / backend URL

    private let apiKey = "YOUR_API_KEY_HERE"
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    func breakdownGoal(text: String, weeks: Int) async throws -> [WeekMilestone] {
        let prompt = """
        Given this goal: "\(text)"
        Timeframe: \(weeks) weeks

        Produce a week-by-week milestone plan. Respond ONLY with JSON:
        {"weeks":[{"week":1,"goal":"short milestone (≤12 words)","tasks":["task1","task2","task3"]},...]}
        Generate exactly \(weeks) week objects. Make milestones concrete and progressive.
        """

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1500,
            "system": "You are a goal planning assistant. Return only valid JSON, no markdown fences.",
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        // Parse Anthropic response envelope
        struct AnthropicResponse: Codable {
            struct Content: Codable { let text: String }
            let content: [Content]
        }
        guard let envelope = try? JSONDecoder().decode(AnthropicResponse.self, from: data),
              let rawText = envelope.content.first?.text,
              let jsonData = rawText.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(WeekBreakdownResponse.self, from: jsonData)
        else { throw AIServiceError.decodingError }

        return parsed.weeks.map { w in
            WeekMilestone(weekNumber: w.week, goal: w.goal, tasks: w.tasks)
        }
    }
}
