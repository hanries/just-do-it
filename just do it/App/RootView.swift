import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        if !store.profile.hasCompletedOnboarding {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                GoalsView()
            }
            .tabItem { Label("Goals", systemImage: "scope") }

            NavigationStack {
                JournalView()
            }
            .tabItem { Label("Daily Log", systemImage: "text.book.closed") }

            NavigationStack {
                GoalProgressView()
            }
            .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .tint(Color.accentTeal)
    }
}

#Preview {
    RootView().environmentObject(AppStore())
}
