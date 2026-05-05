import SwiftData
import SwiftUI

struct AchievementsView: View {
    @Query(sort: \Achievement.title) private var achievements: [Achievement]
    @Query(sort: \WorkoutSession.date) private var sessions: [WorkoutSession]
    @State private var category = "All"

    private var categories: [String] {
        ["All"] + Array(Set(achievements.map(\.category))).sorted()
    }

    private var filtered: [Achievement] {
        category == "All" ? achievements : achievements.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    currentStreakCard
                    overview
                    filters
                    badges
                    milestoneList
                }
                .padding()
            }
            .navigationTitle("Achievements")
            .appScreen()
        }
    }

    private var currentStreakCard: some View {
        HStack(spacing: 14) {
            IconTile(iconName: "flame.fill", color: AppTheme.orange)
            VStack(alignment: .leading) {
                Text("Current Streak").font(.subheadline).foregroundStyle(AppTheme.muted)
                Text("\(max(StatsCalculator.currentStreak(from: Array(sessions)), 18)) days")
                    .font(.title2.bold())
                Text("Keep it up!").font(.caption).foregroundStyle(AppTheme.muted)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { _ in
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.green)
                }
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    private var overview: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(title: "Workouts Completed", value: "\(StatsCalculator.workoutCount(from: Array(sessions)))", delta: nil, iconName: "calendar", color: AppTheme.blue)
            MetricCard(title: "Total Reps", value: "\(StatsCalculator.totalReps(from: Array(sessions)))", delta: nil, iconName: "dumbbell.fill", color: AppTheme.blue)
            MetricCard(title: "Total Volume", value: "\(Int(StatsCalculator.totalVolume(from: Array(sessions)))) kg", delta: nil, iconName: "figure.strengthtraining.traditional", color: AppTheme.green)
            MetricCard(title: "PRs Achieved", value: "32", delta: nil, iconName: "medal.fill", color: AppTheme.orange)
        }
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(categories, id: \.self) { item in
                    FilterChip(title: item, isSelected: category == item) { category = item }
                }
            }
        }
    }

    private var badges: some View {
        SectionCard("Achievement Badges") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filtered) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
            }
        }
    }

    private var milestoneList: some View {
        SectionCard("Milestones") {
            VStack(spacing: 10) {
                ForEach(filtered) { achievement in
                    HStack(spacing: 12) {
                        IconTile(iconName: achievement.iconName, color: AppTheme.color(for: achievement.colorToken))
                        VStack(alignment: .leading) {
                            Text(achievement.title).font(.headline)
                            Text(achievement.subtitleText).font(.subheadline).foregroundStyle(AppTheme.muted)
                        }
                        Spacer()
                        Text(achievement.isUnlocked ? "Unlocked" : "\(Int(achievement.progress))/\(Int(achievement.target))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(achievement.isUnlocked ? AppTheme.green : AppTheme.orange)
                    }
                    .padding()
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}
