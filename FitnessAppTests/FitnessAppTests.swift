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
