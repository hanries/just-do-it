# GoalOS — iOS App Skeleton

A goal-tracking app that uses AI to break big goals into weekly milestones, with a daily journal and progress visualization.

## File Structure

```
GoalOS/
├── App/
│   ├── GoalOSApp.swift          # @main entry point
│   └── RootView.swift           # TabView with 3 tabs
│
├── Models/
│   ├── Models.swift             # Goal, WeekMilestone, JournalEntry, Mood
│   └── AppStore.swift           # ObservableObject state + UserDefaults persistence
│
├── Services/
│   └── AIService.swift          # Anthropic API call for goal breakdown
│
├── Views/
│   ├── Goals/
│   │   ├── GoalsView.swift      # List of all goals
│   │   ├── AddGoalView.swift    # Sheet: input + AI analyze
│   │   └── GoalDetailView.swift # Week-by-week milestone cards
│   ├── Journal/
│   │   └── JournalView.swift    # Daily mood + checklist + reflection
│   └── Progress/
│       └── ProgressView.swift   # Stats + mood calendar + goal progress bars
│
└── Components/
    └── SharedComponents.swift   # CircularProgressView, SectionHeader
```

## Setup

### 1. Create Xcode Project
- File → New → Project → iOS App
- Product Name: `GoalOS`
- Interface: SwiftUI
- Language: Swift

### 2. Add files
Copy all `.swift` files into the project, maintaining the folder grouping.

### 3. Add Color Assets
In `Assets.xcassets`, add these named colors:
- `AccentTeal` — #1D9E75 (light) / #5DCAA5 (dark)
- `MoodTeal`   — #0F6E56 (light) / #9FE1CB (dark)
- `MoodPurple` — #534AB7 (light) / #AFA9EC (dark)
- `MoodAmber`  — #BA7517 (light) / #FAC775 (dark)
- `MoodCoral`  — #D85A30 (light) / #F0997B (dark)

### 4. Wire up AI
In `AIService.swift`, replace `YOUR_API_KEY_HERE` with your Anthropic API key.

> ⚠️ For production: store the key in a backend proxy, not in the app binary.

### 5. Build & Run
Target iOS 17+. No external dependencies needed — pure SwiftUI.

## Architecture Notes

- **AppStore** is the single source of truth, injected via `.environmentObject`
- **AIService** is async/await, called from `AddGoalView` with a `Task {}`
- **Persistence** uses `UserDefaults` + `Codable` — swap for SwiftData/CoreData for larger datasets
- All views have `#Preview` macros for live canvas previews

## Next Steps

- [ ] SwiftData migration for larger datasets
- [ ] Push notifications for daily journal reminders
- [ ] Widget extension for streak + today's tasks
- [ ] iCloud sync via CloudKit
- [ ] Haptic feedback on task completion
- [ ] Share progress as image
