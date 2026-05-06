import SwiftData
import SwiftUI

struct WorkoutHistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(sessions) { session in
                    WorkoutHistoryRow(session: session)
                }
            }
            .padding()
        }
        .navigationTitle("History")
        .appScreen()
    }
}

private struct WorkoutHistoryRow: View {
    let session: WorkoutSession

    private var completedSets: [ExerciseSet] {
        session.completedSets.filter(\.completed)
    }

    private var volume: Double {
        completedSets.reduce(0) { $0 + ($1.weightKg * Double($1.reps)) }
    }

    private var reps: Int {
        completedSets.reduce(0) { $0 + $1.reps }
    }

    private var muscles: [MuscleGroup] {
        Array(Set(completedSets.compactMap(\.exercise).flatMap { [$0.primaryMuscle] + $0.secondaryMuscleGroups }))
            .sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.workoutPlan?.name ?? "Workout")
                        .font(.headline)
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                Text("\(session.durationMinutes) min")
                    .foregroundStyle(AppTheme.green)
                    .font(.subheadline.weight(.bold))
            }
            Text("\(Int(volume)) kg • \(reps) reps • PRs calculated in summary")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(muscles.prefix(5)) { muscle in
                        MuscleTag(title: muscle.rawValue)
                    }
                }
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

