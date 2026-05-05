import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }

            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "dumbbell") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            AchievementsView()
                .tabItem { Label("Achievements", systemImage: "trophy") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(AppTheme.green)
        .preferredColorScheme(.dark)
    }
}
