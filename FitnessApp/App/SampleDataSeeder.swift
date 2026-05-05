import Foundation
import SwiftData

enum SampleDataSeeder {
    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        let exercises = makeExercises()
        exercises.forEach { context.insert($0) }

        let plans = makePlans(exercises: exercises)
        plans.forEach { context.insert($0) }

        makeSessions(plans: plans).forEach { context.insert($0) }
        makeAchievements().forEach { context.insert($0) }

        try? context.save()
    }

    static func makeExercises() -> [Exercise] {
        [
            e("Barbell Bench Press", .chest, [.shoulders, .arms], .barbell),
            e("Incline Dumbbell Press", .chest, [.shoulders], .dumbbell),
            e("Cable Fly", .chest, [], .cable),
            e("Machine Chest Press", .chest, [.arms], .machine),
            e("Push Up", .chest, [.arms, .shoulders], .bodyweight),
            e("Dumbbell Pullover", .chest, [.back], .dumbbell),
            e("Pull Up", .back, [.arms], .bodyweight),
            e("Lat Pulldown", .back, [.arms], .machine),
            e("Barbell Row", .back, [.arms], .barbell),
            e("Seated Cable Row", .back, [.arms], .cable),
            e("Single Arm Dumbbell Row", .back, [.arms], .dumbbell),
            e("Back Extension", .back, [.glutes], .bodyweight),
            e("Barbell Squat", .legs, [.glutes], .barbell),
            e("Leg Press", .legs, [.glutes], .machine),
            e("Romanian Deadlift", .legs, [.glutes, .back], .barbell),
            e("Dumbbell Lunge", .legs, [.glutes], .dumbbell),
            e("Leg Extension", .legs, [], .machine),
            e("Leg Curl", .legs, [.glutes], .machine),
            e("Standing Calf Raise", .calves, [.legs], .machine),
            e("Overhead Press", .shoulders, [.arms], .barbell),
            e("Dumbbell Shoulder Press", .shoulders, [.arms], .dumbbell),
            e("Lateral Raise", .shoulders, [], .dumbbell),
            e("Cable Face Pull", .shoulders, [.back], .cable),
            e("Rear Delt Fly", .shoulders, [.back], .machine),
            e("Arnold Press", .shoulders, [.arms], .dumbbell),
            e("Barbell Curl", .arms, [], .barbell),
            e("Dumbbell Curl", .arms, [], .dumbbell),
            e("Cable Triceps Pushdown", .arms, [], .cable),
            e("Skull Crusher", .arms, [], .barbell),
            e("Hammer Curl", .arms, [], .dumbbell),
            e("Bench Dip", .arms, [.chest], .bodyweight),
            e("Plank", .abs, [], .bodyweight),
            e("Cable Crunch", .abs, [], .cable),
            e("Hanging Leg Raise", .abs, [], .bodyweight),
            e("Machine Crunch", .abs, [], .machine),
            e("Russian Twist", .abs, [], .dumbbell),
            e("Mountain Climber", .abs, [.cardio], .bodyweight),
            e("Treadmill Run", .cardio, [.legs], .machine),
            e("Rowing Machine", .cardio, [.back, .legs], .machine),
            e("Jump Rope", .cardio, [.calves], .bodyweight),
            e("Bike Sprint", .cardio, [.legs], .machine),
            e("Burpee", .cardio, [.chest, .legs], .bodyweight)
        ]
    }

    static func makePlans(exercises: [Exercise]) -> [WorkoutPlan] {
        func find(_ name: String) -> Exercise { exercises.first { $0.name == name } ?? exercises[0] }
        func item(_ name: String, _ sets: Int, _ reps: String, _ rest: Int, _ order: Int) -> WorkoutPlanExercise {
            WorkoutPlanExercise(exercise: find(name), sets: sets, repsText: reps, restSeconds: rest, orderIndex: order)
        }

        let push = WorkoutPlan(name: "Push Day", subtitle: "Chest • Shoulders • Triceps", iconName: "dumbbell.fill", colorToken: "green")
        push.exercises = [
            item("Barbell Bench Press", 4, "8-12", 90, 0),
            item("Incline Dumbbell Press", 3, "8-12", 90, 1),
            item("Cable Fly", 3, "12-15", 60, 2),
            item("Overhead Press", 4, "6-10", 120, 3),
            item("Cable Triceps Pushdown", 3, "10-15", 60, 4)
        ]

        let pull = WorkoutPlan(name: "Pull Day", subtitle: "Back • Biceps • Rear Delts", iconName: "figure.strengthtraining.traditional", colorToken: "purple")
        pull.exercises = [
            item("Pull Up", 4, "6-10", 90, 0),
            item("Barbell Row", 4, "8-10", 120, 1),
            item("Seated Cable Row", 3, "10-12", 90, 2),
            item("Cable Face Pull", 3, "12-15", 60, 3),
            item("Barbell Curl", 3, "8-12", 60, 4),
            item("Hammer Curl", 3, "10-12", 60, 5)
        ]

        let legs = WorkoutPlan(name: "Leg Day", subtitle: "Quads • Hamstrings • Calves", iconName: "figure.strengthtraining.functional", colorToken: "orange")
        legs.exercises = [
            item("Barbell Squat", 4, "5-8", 150, 0),
            item("Leg Press", 4, "10-12", 120, 1),
            item("Romanian Deadlift", 3, "8-10", 120, 2),
            item("Leg Extension", 3, "12-15", 60, 3),
            item("Leg Curl", 3, "12-15", 60, 4),
            item("Standing Calf Raise", 4, "12-20", 45, 5)
        ]

        let upper = WorkoutPlan(name: "Upper Body", subtitle: "Chest • Back • Arms", iconName: "figure.arms.open", colorToken: "blue")
        upper.exercises = [
            item("Push Up", 3, "AMRAP", 60, 0),
            item("Lat Pulldown", 3, "10-12", 90, 1),
            item("Dumbbell Shoulder Press", 3, "8-12", 90, 2),
            item("Dumbbell Curl", 3, "10-12", 60, 3),
            item("Bench Dip", 3, "10-15", 60, 4)
        ]

        return [push, pull, legs, upper]
    }

    static func makeSessions(plans: [WorkoutPlan], calendar: Calendar = .current) -> [WorkoutSession] {
        var sessions: [WorkoutSession] = []
        for dayOffset in stride(from: 29, through: 0, by: -2) {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: .now) else { continue }
            let plan = plans[(29 - dayOffset) % plans.count]
            var sets: [ExerciseSet] = []
            for planExercise in plan.orderedExercises.prefix(4) {
                for index in 0..<planExercise.sets {
                    let base = Double(30 + ((29 - dayOffset) * 3) + index * 5)
                    let reps = max(6, 12 - (index % 3))
                    sets.append(ExerciseSet(exercise: planExercise.exercise, weightKg: base, reps: reps, setIndex: index))
                }
            }
            sessions.append(WorkoutSession(date: date, workoutPlan: plan, durationMinutes: 45 + (dayOffset % 20), completedSets: sets))
        }
        return sessions
    }

    static func makeAchievements() -> [Achievement] {
        [
            Achievement(title: "Current Streak", subtitle: "Keep your streak going", category: "Streaks", iconName: "flame.fill", progress: 18, target: 18, earnedDate: .now, colorToken: "orange"),
            Achievement(title: "Longest Streak", subtitle: "Your best record", category: "Streaks", iconName: "trophy.fill", progress: 42, target: 42, earnedDate: .now, colorToken: "yellow"),
            Achievement(title: "10 Workouts", subtitle: "Complete 10 workouts", category: "Workouts", iconName: "checkmark.seal.fill", progress: 10, target: 10, earnedDate: .now),
            Achievement(title: "50K Reps", subtitle: "Complete 50,000 reps", category: "Reps", iconName: "figure.strengthtraining.traditional", progress: 45892, target: 50000, colorToken: "blue"),
            Achievement(title: "Bench Press PR", subtitle: "Reach 100 kg", category: "Strength", iconName: "dumbbell.fill", progress: 100, target: 100, earnedDate: .now, colorToken: "orange"),
            Achievement(title: "Deadlift PR", subtitle: "Reach 160 kg", category: "Strength", iconName: "dumbbell.fill", progress: 160, target: 160, earnedDate: .now, colorToken: "orange"),
            Achievement(title: "Squat PR", subtitle: "Reach 140 kg", category: "Strength", iconName: "dumbbell.fill", progress: 140, target: 140, earnedDate: .now),
            Achievement(title: "Barbell Reps", subtitle: "Complete 25,000 barbell reps", category: "Volume", iconName: "dumbbell.fill", progress: 22345, target: 25000, colorToken: "purple"),
            Achievement(title: "Dumbbell Reps", subtitle: "Complete 20,000 dumbbell reps", category: "Volume", iconName: "dumbbell.fill", progress: 15678, target: 20000, colorToken: "orange"),
            Achievement(title: "Cable Reps", subtitle: "Complete 10,000 cable reps", category: "Volume", iconName: "figure.strengthtraining.traditional", progress: 7869, target: 10000)
        ]
    }

    private static func e(_ name: String, _ primary: MuscleGroup, _ secondary: [MuscleGroup], _ equipment: EquipmentType) -> Exercise {
        Exercise(name: name, primaryMuscle: primary, secondaryMuscles: secondary, equipment: equipment, instructions: "Use controlled form and full range of motion.")
    }
}
