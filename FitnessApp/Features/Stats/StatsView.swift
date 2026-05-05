import SwiftData
import SwiftUI

struct StatsView: View {
    @Query(sort: \WorkoutSession.date) private var sessions: [WorkoutSession]
    @State private var period = "1M"
    private let periods = ["1W", "1M", "3M", "6M", "1Y"]

    private var sessionArray: [WorkoutSession] { Array(sessions) }
    private var muscleShares: [MuscleShare] {
        let totals = StatsCalculator.muscleTotals(from: sessionArray)
        return MuscleGroup.chartGroups.map { MuscleShare(group: $0, value: totals[$0, default: 0]) }
            .filter { $0.value > 0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    periodPicker
                    metrics
                    SectionCard("Volume Over Time") {
                        StrengthLineChart(data: StatsCalculator.dailyVolume(from: sessionArray))
                    }
                    SectionCard("Muscle Group Breakdown") {
                        MuscleBreakdownChart(shares: muscleShares)
                        muscleLegend
                    }
                }
                .padding()
            }
            .navigationTitle("Stats")
            .appScreen()
        }
    }

    private var periodPicker: some View {
        HStack {
            ForEach(periods, id: \.self) { item in
                FilterChip(title: item, isSelected: item == period) { period = item }
            }
        }
    }

    private var metrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(title: "Total Workouts", value: "\(StatsCalculator.workoutCount(from: sessionArray))", delta: "↑ 12.5%", iconName: "calendar", color: .purple)
            MetricCard(title: "Total Reps", value: "\(StatsCalculator.totalReps(from: sessionArray))", delta: "↑ 16.3%", iconName: "dumbbell.fill", color: AppTheme.green)
            MetricCard(title: "Total Volume", value: "\(Int(StatsCalculator.totalVolume(from: sessionArray))) kg", delta: "↑ 18.6%", iconName: "chart.bar.fill", color: AppTheme.blue)
            MetricCard(title: "Strength Growth", value: "\(Int(StatsCalculator.maxWeight(from: sessionArray))) kg", delta: "↑ 8.7%", iconName: "crown.fill", color: AppTheme.orange)
        }
    }

    private var muscleLegend: some View {
        VStack(spacing: 8) {
            ForEach(muscleShares) { share in
                HStack {
                    Circle().fill(AppTheme.green).frame(width: 8, height: 8)
                    Text(share.group.rawValue)
                    Spacer()
                    Text("\(Int(share.value)) kg")
                        .foregroundStyle(AppTheme.muted)
                }
                .font(.subheadline)
            }
        }
    }
}
