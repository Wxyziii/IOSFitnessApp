import Combine
import SwiftData
import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date) private var previousSessions: [WorkoutSession]

    let plan: WorkoutPlan

    @State private var startDate = Date()
    @State private var now = Date()
    @State private var exercises: [ActiveExerciseState] = []
    @State private var restEndDate: Date?
    @State private var restCompleteShown = false
    @State private var summary: WorkoutSummary?
    @State private var showingSummary = false
    @State private var liveActivityManager = WorkoutLiveActivityManager()
    @State private var notificationScheduler = RestNotificationScheduler()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var elapsedSeconds: Int {
        max(0, Int(now.timeIntervalSince(startDate)))
    }

    private var restState: RestTimerState {
        RestTimerState(endDate: restEndDate, now: now)
    }

    private var completedSets: [ActiveSetState] {
        exercises.flatMap(\.sets).filter(\.completed)
    }

    private var totalSets: Int {
        exercises.flatMap(\.sets).count
    }

    private var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.filter(\.completed).reduce(0) { $0 + ($1.weightKg * Double($1.reps)) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if restEndDate != nil {
                    restTimerCard
                }
                exerciseSections
                finishButtons
            }
            .padding()
        }
        .navigationTitle("Active Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") {
                    cancelWorkout()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationDestination(isPresented: $showingSummary) {
            if let summary {
                WorkoutSummaryView(summary: summary)
            }
        }
        .onAppear(perform: startIfNeeded)
        .onReceive(timer) { date in
            now = date
            handleRestTick()
        }
        .appScreen()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(plan.name)
                .font(.largeTitle.bold())
            HStack {
                WorkoutMetricPill(title: "Time", value: elapsedText)
                WorkoutMetricPill(title: "Sets", value: "\(completedSets.count)/\(totalSets)")
                WorkoutMetricPill(title: "Volume", value: "\(Int(totalVolume)) kg")
            }
        }
        .cardStyle()
    }

    private var restTimerCard: some View {
        SectionCard("Rest Timer") {
            VStack(alignment: .leading, spacing: 14) {
                Text(restState.isComplete ? "Rest complete" : restCountdownText)
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(restState.isComplete ? AppTheme.green : .white)
                    .monospacedDigit()
                HStack {
                    Button("Skip") { skipRest() }
                    Button("+30s") { addRest(seconds: 30) }
                    Button("Stop") { stopRest() }
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.green)
            }
        }
    }

    private var exerciseSections: some View {
        VStack(spacing: 14) {
            ForEach($exercises) { $exerciseState in
                ActiveExerciseCard(exerciseState: $exerciseState) { set in
                    complete(set: set, in: exerciseState)
                }
            }
        }
    }

    private var finishButtons: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: "Finish Workout", action: finishWorkout)
                .disabled(completedSets.isEmpty)
                .opacity(completedSets.isEmpty ? 0.45 : 1)
            Button("Cancel Workout") { cancelWorkout() }
                .font(.headline)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding()
        }
    }

    private var elapsedText: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return "\(minutes):\(seconds.formatted(.number.precision(.integerLength(2))))"
    }

    private var restCountdownText: String {
        let seconds = restState.remainingSeconds
        return "\(seconds / 60):\((seconds % 60).formatted(.number.precision(.integerLength(2))))"
    }

    private func startIfNeeded() {
        guard exercises.isEmpty else { return }
        startDate = .now
        now = startDate
        exercises = plan.orderedExercises.compactMap { item in
            guard let exercise = item.exercise else { return nil }
            let reps = Self.defaultReps(from: item.repsText)
            let sets = (0..<item.sets).map { ActiveSetState(setIndex: $0 + 1, weightKg: 0, reps: reps) }
            return ActiveExerciseState(planExercise: item, exercise: exercise, sets: sets)
        }
        Task { await liveActivityManager.start(workoutName: plan.name, state: liveState()) }
    }

    private func complete(set: ActiveSetState, in exerciseState: ActiveExerciseState) {
        guard set.completed else { return }
        restEndDate = RestTimerState.endDate(durationSeconds: exerciseState.planExercise.restSeconds)
        restCompleteShown = false
        Task {
            await notificationScheduler.scheduleRestComplete(after: exerciseState.planExercise.restSeconds)
            await liveActivityManager.update(liveState())
        }
    }

    private func handleRestTick() {
        guard restState.isComplete, restCompleteShown == false else { return }
        restCompleteShown = true
        Task { await liveActivityManager.update(liveState(isResting: false)) }
    }

    private func skipRest() {
        stopRest()
        Task { await liveActivityManager.update(liveState(isResting: false)) }
    }

    private func addRest(seconds: Int) {
        let base = restEndDate ?? now
        restEndDate = base.addingTimeInterval(TimeInterval(seconds))
        restCompleteShown = false
        Task {
            await notificationScheduler.scheduleRestComplete(after: restState.remainingSeconds)
            await liveActivityManager.update(liveState())
        }
    }

    private func stopRest() {
        restEndDate = nil
        restCompleteShown = false
        notificationScheduler.cancelRestNotifications()
    }

    private func finishWorkout() {
        let sets = makeCompletedExerciseSets()
        let prior = previousSessions
        let duration = max(1, Int(ceil(now.timeIntervalSince(startDate) / 60)))
        let prs = WorkoutPRDetector.detect(newSets: sets, previousSessions: prior)
        let session = WorkoutSession(date: startDate, workoutPlan: plan, durationMinutes: duration, completedSets: sets)
        modelContext.insert(session)
        try? modelContext.save()

        notificationScheduler.cancelRestNotifications()
        let finalSummary = WorkoutSummary(workoutName: plan.name, durationMinutes: duration, completedSets: sets, prs: prs)
        summary = finalSummary
        showingSummary = true
        Task { await liveActivityManager.end(liveState(isResting: false)) }
    }

    private func cancelWorkout() {
        notificationScheduler.cancelRestNotifications()
        Task { await liveActivityManager.end(liveState(isResting: false)) }
        dismiss()
    }

    private func makeCompletedExerciseSets() -> [ExerciseSet] {
        exercises.flatMap { activeExercise in
            activeExercise.sets.filter(\.completed).map { set in
                ExerciseSet(
                    exercise: activeExercise.exercise,
                    weightKg: set.weightKg,
                    reps: set.reps,
                    setIndex: set.setIndex,
                    completed: true
                )
            }
        }
    }

    private func liveState(isResting overrideResting: Bool? = nil) -> WorkoutLiveActivityAttributes.ContentState {
        let next = nextSetContext()
        return WorkoutLiveActivityAttributes.ContentState(
            currentExerciseName: next.exerciseName,
            currentSet: next.currentSet,
            totalSets: totalSets,
            restEndDate: restEndDate,
            isResting: overrideResting ?? restState.isRunning,
            elapsedWorkoutTime: TimeInterval(elapsedSeconds),
            completedSets: completedSets.count,
            totalVolume: totalVolume
        )
    }

    private func nextSetContext() -> (exerciseName: String, currentSet: Int) {
        for exercise in exercises {
            if let next = exercise.sets.first(where: { !$0.completed }) {
                return (exercise.exercise.name, next.setIndex)
            }
        }
        return (exercises.last?.exercise.name ?? "Workout", totalSets)
    }

    static func defaultReps(from text: String) -> Int {
        let numbers = text.split { !$0.isNumber }.compactMap { Int($0) }
        return numbers.first ?? 10
    }
}

struct ActiveExerciseState: Identifiable {
    let id = UUID()
    let planExercise: WorkoutPlanExercise
    let exercise: Exercise
    var sets: [ActiveSetState]
}

struct ActiveSetState: Identifiable, Equatable {
    let id = UUID()
    let setIndex: Int
    var weightKg: Double
    var reps: Int
    var completed = false
}

private struct ActiveExerciseCard: View {
    @Binding var exerciseState: ActiveExerciseState
    let onComplete: (ActiveSetState) -> Void

    var body: some View {
        SectionCard(exerciseState.exercise.name) {
            VStack(spacing: 10) {
                ForEach($exerciseState.sets) { $set in
                    HStack(spacing: 10) {
                        Text("Set \(set.setIndex)")
                            .font(.subheadline.weight(.bold))
                            .frame(width: 48, alignment: .leading)
                        TextField("kg", value: $set.weightKg, format: .number.precision(.fractionLength(0)))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                        TextField("reps", value: $set.reps, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            set.completed.toggle()
                            if set.completed {
                                onComplete(set)
                            }
                        } label: {
                            Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(set.completed ? AppTheme.green : AppTheme.muted)
                        }
                        .accessibilityLabel(set.completed ? "Set completed" : "Complete set")
                    }
                }
            }
        }
    }
}

struct WorkoutMetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(AppTheme.muted)
            Text(value).font(.headline).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
