import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedTab: Tab = .goals

    enum Tab: String { case goals, journal, progress }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                GoalsView()
            }
            .tabItem { Label("Goals", systemImage: "scope") }
            .tag(Tab.goals)

            NavigationStack {
                JournalView()
            }
            .tabItem { Label("Daily Log", systemImage: "text.book.closed") }
            .tag(Tab.journal)

            NavigationStack {
                GoalProgressScreen()
            }
            .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
            .tag(Tab.progress)
        }
        .tint(Color("AccentTeal"))
    }
}

#Preview {
    RootView()
        .environmentObject(AppStore())
}
