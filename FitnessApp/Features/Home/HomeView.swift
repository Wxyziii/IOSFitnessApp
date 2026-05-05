import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \WorkoutPlan.createdAt) private var plans: [WorkoutPlan]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    WeeklyStreakStrip(completedDays: [0, 1, 2, 3], selectedDay: 3)
                    SectionCard {
                        VStack(alignment: .leading, spacing: 16) {
                            legend
                            MuscleMapView(trainedGroups: Set(StatsCalculator.muscleTotals(from: Array(sessions)).keys))
                        }
                    }
                    SectionCard("Recent Plans", actionTitle: "View all") {} content: {
                        VStack(spacing: 10) {
                            ForEach(Array(plans.prefix(4)).indices, id: \.self) { index in
                                WorkoutPlanRow(plan: plans[index], accessoryText: index == 0 ? "Today" : "\(index * 2) days ago")
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .appScreen()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Good morning, Alex 👋")
                    .font(.largeTitle.bold())
                Text("Keep the streak going 🔥")
                    .font(.headline)
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
            StreakPill(count: max(StatsCalculator.currentStreak(from: Array(sessions)), 12))
        }
        .padding(.top, 24)
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Trained", systemImage: "circle.fill")
                .foregroundStyle(AppTheme.green)
            Label("Not trained", systemImage: "circle.fill")
                .foregroundStyle(AppTheme.muted)
        }
        .font(.subheadline.weight(.semibold))
    }
}
