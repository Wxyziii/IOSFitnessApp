import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \WorkoutPlan.createdAt) private var plans: [WorkoutPlan]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \WeekPlanDay.date) private var weekPlanDays: [WeekPlanDay]
    @State private var selectedMuscle: MuscleGroup?
    @State private var showingWeekPlanner = false

    private var muscleTotals: [MuscleGroup: Double] {
        StatsCalculator.muscleTotals(from: Array(sessions))
    }

    private var currentStreak: Int {
        StatsCalculator.currentStreak(from: Array(sessions), weekPlanDays: Array(weekPlanDays))
    }

    private var fulfilledWeekdays: Set<Int> {
        StatsCalculator.fulfilledWeekdayIndexes(from: Array(sessions), weekPlanDays: Array(weekPlanDays))
    }

    private var selectedWeekdayIndex: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start = SampleDataSeeder.startOfWeek(containing: today, calendar: calendar)
        return min(max(calendar.dateComponents([.day], from: start, to: today).day ?? 0, 0), 6)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    planWeekButton
                    WeeklyStreakStrip(completedDays: fulfilledWeekdays, selectedDay: selectedWeekdayIndex)
                    SectionCard {
                        VStack(alignment: .leading, spacing: 16) {
                            legend
                            MuscleMapView(activations: muscleTotals, selectedMuscle: selectedMuscle) { muscle in
                                selectedMuscle = muscle
                            }
                        }
                    }
                    SectionCard("Recent Plans", actionTitle: "View all") {} content: {
                        VStack(spacing: 10) {
                            ForEach(Array(plans.prefix(4)).indices, id: \.self) { index in
                                NavigationLink {
                                    WorkoutPlanDetailView(plan: plans[index])
                                } label: {
                                    WorkoutPlanRow(plan: plans[index], accessoryText: index == 0 ? "Today" : "\(index * 2) days ago")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedMuscle) { muscle in
                MuscleDetailSheet(
                    muscle: muscle,
                    volume: muscleTotals[muscle, default: 0],
                    lastTrainedDate: StatsCalculator.lastTrainedDate(for: muscle, sessions: Array(sessions)),
                    exercises: exercises.filter { $0.primaryMuscle == muscle || $0.secondaryMuscleGroups.contains(muscle) }
                )
            }
            .sheet(isPresented: $showingWeekPlanner) {
                WeekPlannerView()
            }
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
            StreakPill(count: currentStreak)
        }
        .padding(.top, 24)
    }

    private var planWeekButton: some View {
        Button {
            showingWeekPlanner = true
        } label: {
            HStack {
                Label("Plan your week", systemImage: "calendar.badge.plus")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.muted)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Plan your week")
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

private struct MuscleDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let muscle: MuscleGroup
    let volume: Double
    let lastTrainedDate: Date?
    let exercises: [Exercise]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    MetricCard(title: "Recent Volume", value: "\(Int(volume)) kg", delta: nil, iconName: "figure.strengthtraining.traditional", color: AppTheme.green)
                    SectionCard("Last Trained") {
                        Text(lastTrainedDate?.formatted(date: .abbreviated, time: .omitted) ?? "No recent session")
                            .foregroundStyle(AppTheme.muted)
                    }
                    SectionCard("Targeting Exercises") {
                        VStack(spacing: 10) {
                            ForEach(exercises) { exercise in
                                HStack {
                                    IconTile(iconName: exercise.iconName, color: AppTheme.green)
                                    VStack(alignment: .leading) {
                                        Text(exercise.name).font(.headline)
                                        Text("\(exercise.primaryMuscle.rawValue) • \(exercise.equipment.rawValue)")
                                            .font(.subheadline)
                                            .foregroundStyle(AppTheme.muted)
                                    }
                                    Spacer()
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                    PrimaryButton(title: "Create Workout With These") {
                        createWorkout()
                    }
                        .opacity(0.7)
                }
                .padding()
            }
            .navigationTitle(muscle.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .appScreen()
        }
    }

    private func createWorkout() {
        let pickedExercises = Array(exercises.prefix(6))
        let plan = WorkoutPlan(name: "\(muscle.rawValue) Focus", subtitle: pickedExercises.map { $0.primaryMuscle.legacyBucket }.uniqued().joined(separator: " • "), iconName: "figure.strengthtraining.traditional", colorToken: "green")
        plan.exercises = pickedExercises.enumerated().map { index, exercise in
            WorkoutPlanExercise(exercise: exercise, sets: 3, repsText: "8-12", restSeconds: 90, orderIndex: index)
        }
        modelContext.insert(plan)
        try? modelContext.save()
        dismiss()
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
