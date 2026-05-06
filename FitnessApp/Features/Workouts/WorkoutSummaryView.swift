import SwiftUI

struct WorkoutSummaryView: View {
    let summary: WorkoutSummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                MuscleMapView(activations: summary.muscleActivations)
                    .frame(maxHeight: 340)
                    .cardStyle()
                prSection
                completedExerciseSection
            }
            .padding()
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .appScreen()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(summary.workoutName)
                .font(.largeTitle.bold())
            HStack {
                WorkoutMetricPill(title: "Duration", value: "\(summary.durationMinutes) min")
                WorkoutMetricPill(title: "Sets", value: "\(summary.totalSets)")
            }
            HStack {
                WorkoutMetricPill(title: "Reps", value: "\(summary.totalReps)")
                WorkoutMetricPill(title: "Volume", value: "\(Int(summary.totalVolume)) kg")
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(summary.musclesTrained) { muscle in
                        MuscleTag(title: muscle.rawValue)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var prSection: some View {
        SectionCard("PRs") {
            if summary.prs.isEmpty {
                Text("No new PRs this workout")
                    .foregroundStyle(AppTheme.muted)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(summary.prs) { pr in
                        Label(pr.message, systemImage: "star.fill")
                            .foregroundStyle(AppTheme.green)
                    }
                }
            }
        }
    }

    private var completedExerciseSection: some View {
        SectionCard("Completed Sets") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(summary.completedSets.filter(\.completed)) { set in
                    HStack {
                        Text(set.exercise?.name ?? "Exercise")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(set.weightKg)) kg x \(set.reps)")
                            .foregroundStyle(AppTheme.muted)
                            .monospacedDigit()
                    }
                }
            }
        }
    }
}
