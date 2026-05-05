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
