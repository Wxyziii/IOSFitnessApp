import SwiftUI

struct WorkoutPlanDetailView: View {
    let plan: WorkoutPlan

    private var estimatedDuration: Int {
        let workSeconds = plan.orderedExercises.reduce(0) { total, item in
            total + (item.sets * 45) + (max(item.sets - 1, 0) * item.restSeconds)
        }
        return max(15, Int(ceil(Double(workSeconds) / 60.0)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                exerciseList
                NavigationLink {
                    ActiveWorkoutView(plan: plan)
                } label: {
                    Text("Start Workout")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.green, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start \(plan.name)")
            }
            .padding()
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .appScreen()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            IconTile(iconName: plan.iconName, color: AppTheme.color(for: plan.colorToken))
            Text(plan.name)
                .font(.largeTitle.bold())
            Text(plan.subtitle)
                .font(.headline)
                .foregroundStyle(AppTheme.muted)
            HStack(spacing: 16) {
                Label("\(estimatedDuration) min", systemImage: "clock")
                Label("\(plan.orderedExercises.count) exercises", systemImage: "list.bullet")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.green)
        }
        .cardStyle()
    }

    private var exerciseList: some View {
        SectionCard("Plan") {
            VStack(spacing: 12) {
                ForEach(plan.orderedExercises) { item in
                    WorkoutPlanExerciseDetailRow(item: item)
                }
            }
        }
    }
}

private struct WorkoutPlanExerciseDetailRow: View {
    let item: WorkoutPlanExercise

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconTile(iconName: item.exercise?.iconName ?? "dumbbell.fill", color: AppTheme.green)
            VStack(alignment: .leading, spacing: 8) {
                Text(item.exercise?.name ?? "Exercise")
                    .font(.headline)
                Text("\(item.sets) sets • \(item.repsText) reps • \(item.restSeconds)s rest")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                if let exercise = item.exercise {
                    HStack {
                        MuscleTag(title: exercise.primaryMuscle.rawValue)
                        ForEach(exercise.secondaryMuscleGroups.prefix(2)) { muscle in
                            MuscleTag(title: muscle.rawValue)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

