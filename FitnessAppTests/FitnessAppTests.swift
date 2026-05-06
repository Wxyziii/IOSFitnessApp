import Foundation
import SwiftData
import Testing
@testable import FitnessApp

@MainActor
struct FitnessAppTests {
    @Test func inMemoryContainerInitializes() throws {
        _ = try makeContainer()
    }

    @Test func sampleSeedingDoesNotDuplicate() throws {
        let container = try makeContainer()
        SampleDataSeeder.seedIfNeeded(in: container.mainContext)
        SampleDataSeeder.seedIfNeeded(in: container.mainContext)

        let exercises = try container.mainContext.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count >= 40)
        #expect(Set(exercises.map(\.name)).count == exercises.count)
    }

    @Test func totalRepsCalculation() throws {
        let sessions = try seededSessions()
        #expect(StatsCalculator.totalReps(from: sessions) > 0)
    }

    @Test func totalVolumeCalculation() throws {
        let sessions = try seededSessions()
        #expect(StatsCalculator.totalVolume(from: sessions) > 0)
    }

    @Test func maxWeightCalculation() throws {
        let sessions = try seededSessions()
        #expect(StatsCalculator.maxWeight(from: sessions) > 0)
    }

    @Test func workoutCountCalculation() throws {
        let sessions = try seededSessions()
        #expect(StatsCalculator.workoutCount(from: sessions) > 0)
    }

    @Test func streakCalculation() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let exercise = Exercise(name: "Push Up", primaryMuscle: .chest, equipment: .bodyweight, instructions: "")
        let sessions = [0, 1, 2].compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today).map {
                WorkoutSession(date: $0, workoutPlan: nil, durationMinutes: 30, completedSets: [
                    ExerciseSet(exercise: exercise, weightKg: 0, reps: 10, setIndex: 0)
                ])
            }
        }
        #expect(StatsCalculator.currentStreak(from: sessions, calendar: calendar, today: today) == 3)
    }

    @Test func muscleGroupAggregation() throws {
        let sessions = try seededSessions()
        let totals = StatsCalculator.muscleTotals(from: sessions)
        #expect(totals[.chest, default: 0] > 0)
    }

    @Test func primaryMuscleActivationUsesFullVolume() {
        let exercise = Exercise(name: "Bench", primaryMuscle: .chest, secondaryMuscles: [.triceps], equipment: .barbell, instructions: "")
        let session = WorkoutSession(date: .now, workoutPlan: nil, durationMinutes: 30, completedSets: [
            ExerciseSet(exercise: exercise, weightKg: 100, reps: 5, setIndex: 0)
        ])

        let totals = StatsCalculator.muscleTotals(from: [session])
        #expect(totals[.chest] == 500)
    }

    @Test func secondaryMuscleActivationUsesPartialVolume() {
        let exercise = Exercise(name: "Bench", primaryMuscle: .chest, secondaryMuscles: [.triceps], equipment: .barbell, instructions: "")
        let session = WorkoutSession(date: .now, workoutPlan: nil, durationMinutes: 30, completedSets: [
            ExerciseSet(exercise: exercise, weightKg: 100, reps: 5, setIndex: 0)
        ])

        let totals = StatsCalculator.muscleTotals(from: [session])
        #expect(totals[.triceps] == 175)
    }

    @Test func sampleExercisesUseSpecificMuscles() throws {
        let exercises = SampleDataSeeder.makeExercises()
        let bench = try #require(exercises.first { $0.name == "Barbell Bench Press" })
        let pullUp = try #require(exercises.first { $0.name == "Pull Up" })
        let squat = try #require(exercises.first { $0.name == "Barbell Squat" })

        #expect(bench.primaryMuscle == .chest)
        #expect(bench.secondaryMuscleGroups == [.frontDelts, .triceps])
        #expect(pullUp.primaryMuscle == .lats)
        #expect(pullUp.secondaryMuscleGroups.contains(.upperBack))
        #expect(squat.primaryMuscle == .quads)
    }

    @Test func svgRegionMappingIntegrity() {
        #expect(MuscleMapRegionCatalog.regions.isEmpty == false)
        #expect(MuscleMapRegionCatalog.regions.count == MuscleMapRegionCatalog.muscleByRegionID.count)
        #expect(MuscleMapRegionCatalog.muscleByRegionID["front_chest_left"] == .chest)
        #expect(MuscleMapRegionCatalog.muscleByRegionID["back_lats"] == .lats)
        #expect(MuscleMapRegionCatalog.regions.allSatisfy { $0.assetRegionName == $0.svgRegionID })
    }

    @Test func workoutPlanOrdering() {
        let exercise = Exercise(name: "Bench", primaryMuscle: .chest, equipment: .barbell, instructions: "")
        let plan = WorkoutPlan(name: "Test", subtitle: "")
        plan.exercises = [
            WorkoutPlanExercise(exercise: exercise, sets: 1, repsText: "1", restSeconds: 30, orderIndex: 2),
            WorkoutPlanExercise(exercise: exercise, sets: 1, repsText: "1", restSeconds: 30, orderIndex: 0),
            WorkoutPlanExercise(exercise: exercise, sets: 1, repsText: "1", restSeconds: 30, orderIndex: 1)
        ]
        #expect(plan.orderedExercises.map(\.orderIndex) == [0, 1, 2])
    }

    @Test func weeklyPlanRestDaysKeepStreak() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let exercise = Exercise(name: "Bench", primaryMuscle: .chest, equipment: .barbell, instructions: "")
        let plan = WorkoutPlan(name: "Push", subtitle: "")
        let sessions = [
            WorkoutSession(date: twoDaysAgo, workoutPlan: plan, durationMinutes: 30, completedSets: [
                ExerciseSet(exercise: exercise, weightKg: 80, reps: 8, setIndex: 0)
            ])
        ]
        let weekPlan = [
            WeekPlanDay(date: today, workoutPlan: plan),
            WeekPlanDay(date: yesterday, isRestDay: true),
            WeekPlanDay(date: twoDaysAgo, workoutPlan: plan)
        ]

        #expect(StatsCalculator.currentStreak(from: sessions, weekPlanDays: weekPlan, calendar: calendar, today: today) == 2)
    }

    @Test func unplannedDayBreaksWeeklyStreak() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let plan = WorkoutPlan(name: "Push", subtitle: "")
        let weekPlan = [
            WeekPlanDay(date: yesterday, isRestDay: true),
            WeekPlanDay(date: twoDaysAgo, workoutPlan: plan)
        ]

        #expect(StatsCalculator.currentStreak(from: [], weekPlanDays: weekPlan, calendar: calendar, today: today) == 0)
    }

    @Test func missedPlannedWorkoutBreaksWeeklyStreak() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let plan = WorkoutPlan(name: "Push", subtitle: "")
        let weekPlan = [
            WeekPlanDay(date: today, isRestDay: true),
            WeekPlanDay(date: yesterday, workoutPlan: plan)
        ]

        #expect(StatsCalculator.currentStreak(from: [], weekPlanDays: weekPlan, calendar: calendar, today: today) == 1)
    }

    @Test func fulfilledWeekdayIndexesIncludeRestAndCompletedWorkout() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let start = SampleDataSeeder.startOfWeek(containing: today, calendar: calendar)
        let workoutDate = calendar.date(byAdding: .day, value: 1, to: start)!
        let restDate = calendar.date(byAdding: .day, value: 2, to: start)!
        let exercise = Exercise(name: "Bench", primaryMuscle: .chest, equipment: .barbell, instructions: "")
        let plan = WorkoutPlan(name: "Push", subtitle: "")
        let sessions = [
            WorkoutSession(date: workoutDate, workoutPlan: plan, durationMinutes: 30, completedSets: [
                ExerciseSet(exercise: exercise, weightKg: 80, reps: 8, setIndex: 0)
            ])
        ]
        let indexes = StatsCalculator.fulfilledWeekdayIndexes(
            from: sessions,
            weekPlanDays: [WeekPlanDay(date: workoutDate, workoutPlan: plan), WeekPlanDay(date: restDate, isRestDay: true)],
            calendar: calendar,
            today: today
        )

        #expect(indexes.contains(1))
        #expect(indexes.contains(2))
    }

    @Test func workoutSessionCreatedFromCompletedSets() {
        let exercise = Exercise(name: "Bench", primaryMuscle: .chest, equipment: .barbell, instructions: "")
        let sets = [
            ExerciseSet(exercise: exercise, weightKg: 80, reps: 8, setIndex: 1),
            ExerciseSet(exercise: exercise, weightKg: 85, reps: 6, setIndex: 2)
        ]
        let session = WorkoutSession(date: .now, workoutPlan: nil, durationMinutes: 42, completedSets: sets)

        #expect(session.completedSets.count == 2)
        #expect(session.durationMinutes == 42)
    }

    @Test func incompleteSetsDoNotCountTowardStats() {
        let exercise = Exercise(name: "Bench", primaryMuscle: .chest, equipment: .barbell, instructions: "")
        let session = WorkoutSession(date: .now, workoutPlan: nil, durationMinutes: 30, completedSets: [
            ExerciseSet(exercise: exercise, weightKg: 100, reps: 5, setIndex: 1, completed: true),
            ExerciseSet(exercise: exercise, weightKg: 200, reps: 20, setIndex: 2, completed: false)
        ])

        #expect(StatsCalculator.totalVolume(from: [session]) == 500)
        #expect(StatsCalculator.totalReps(from: [session]) == 5)
    }

    @Test func prDetectionWeightVolumeAndReps() {
        let exercise = Exercise(name: "Squat", primaryMuscle: .quads, equipment: .barbell, instructions: "")
        let previous = WorkoutSession(date: .now, workoutPlan: nil, durationMinutes: 30, completedSets: [
            ExerciseSet(exercise: exercise, weightKg: 100, reps: 5, setIndex: 1),
            ExerciseSet(exercise: exercise, weightKg: 90, reps: 6, setIndex: 2)
        ])
        let newSets = [
            ExerciseSet(exercise: exercise, weightKg: 120, reps: 8, setIndex: 1),
            ExerciseSet(exercise: exercise, weightKg: 110, reps: 8, setIndex: 2)
        ]

        let prs = WorkoutPRDetector.detect(newSets: newSets, previousSessions: [previous])
        #expect(prs.contains { $0.type == .weight && $0.value == 120 })
        #expect(prs.contains { $0.type == .reps && $0.value == 8 })
        #expect(prs.contains { $0.type == .volume && $0.value == 1840 })
    }

    @Test func restTimerStateCalculation() {
        let now = Date(timeIntervalSince1970: 1_000)
        let state = RestTimerState(endDate: now.addingTimeInterval(90), now: now.addingTimeInterval(30))

        #expect(state.remainingSeconds == 60)
        #expect(state.isRunning)
        #expect(RestTimerState(endDate: now, now: now).isComplete)
    }

    @Test func liveActivityStateModelCreation() {
        let state = WorkoutLiveActivityAttributes.ContentState(
            currentExerciseName: "Bench Press",
            currentSet: 2,
            totalSets: 12,
            restEndDate: Date(timeIntervalSince1970: 2_000),
            isResting: true,
            elapsedWorkoutTime: 600,
            completedSets: 3,
            totalVolume: 1200
        )

        #expect(state.currentExerciseName == "Bench Press")
        #expect(state.isResting)
        #expect(state.totalVolume == 1200)
    }

    @Test func notificationSchedulingRequestModel() {
        let request = RestNotificationScheduler.makeRequest(seconds: 0)

        #expect(request.identifier == RestNotificationScheduler.restIdentifier)
        #expect(request.title == "Rest complete")
        #expect(request.body == "Time for your next set.")
        #expect(request.seconds == 1)
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: AppSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: AppSchema.schema, configurations: [configuration])
    }

    private func seededSessions() throws -> [WorkoutSession] {
        let container = try makeContainer()
        SampleDataSeeder.seedIfNeeded(in: container.mainContext)
        return try container.mainContext.fetch(FetchDescriptor<WorkoutSession>())
    }
}
