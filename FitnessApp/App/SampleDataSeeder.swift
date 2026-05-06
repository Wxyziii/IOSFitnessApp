import Foundation
import SwiftData

enum SampleDataSeeder {
    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else {
            seedWeekPlanIfNeeded(in: context)
            return
        }

        let exercises = makeExercises()
        exercises.forEach { context.insert($0) }

        let plans = makePlans(exercises: exercises)
        plans.forEach { context.insert($0) }

        makeSessions(plans: plans).forEach { context.insert($0) }
        makeAchievements().forEach { context.insert($0) }
        makeWeekPlan(plans: plans).forEach { context.insert($0) }

        try? context.save()
    }

    static func makeExercises() -> [Exercise] {
        [
            e("Barbell Bench Press", .chest, [.frontDelts, .triceps], .barbell),
            e("Incline Dumbbell Press", .chest, [.frontDelts, .triceps], .dumbbell),
            e("Cable Fly", .chest, [], .cable),
            e("Machine Chest Press", .chest, [.frontDelts, .triceps], .machine),
            e("Push Up", .chest, [.frontDelts, .triceps], .bodyweight),
            e("Dumbbell Pullover", .lats, [.chest, .triceps], .dumbbell),
            e("Pull Up", .lats, [.biceps, .upperBack], .bodyweight),
            e("Lat Pulldown", .lats, [.biceps, .upperBack], .machine),
            e("Barbell Row", .upperBack, [.lats, .biceps], .barbell),
            e("Seated Cable Row", .upperBack, [.lats, .biceps], .cable),
            e("Single Arm Dumbbell Row", .lats, [.upperBack, .biceps], .dumbbell),
            e("Back Extension", .hamstrings, [.glutes, .upperBack], .bodyweight),
            e("Barbell Squat", .quads, [.glutes, .hamstrings], .barbell),
            e("Leg Press", .quads, [.glutes, .hamstrings], .machine),
            e("Romanian Deadlift", .hamstrings, [.glutes, .upperBack], .barbell),
            e("Dumbbell Lunge", .quads, [.glutes, .hamstrings], .dumbbell),
            e("Leg Extension", .quads, [], .machine),
            e("Leg Curl", .hamstrings, [.glutes], .machine),
            e("Standing Calf Raise", .calves, [], .machine),
            e("Overhead Press", .frontDelts, [.sideDelts, .triceps], .barbell),
            e("Dumbbell Shoulder Press", .frontDelts, [.sideDelts, .triceps], .dumbbell),
            e("Lateral Raise", .sideDelts, [], .dumbbell),
            e("Cable Face Pull", .rearDelts, [.upperBack, .traps], .cable),
            e("Rear Delt Fly", .rearDelts, [.upperBack], .machine),
            e("Arnold Press", .frontDelts, [.sideDelts, .triceps], .dumbbell),
            e("Barbell Curl", .biceps, [.forearms], .barbell),
            e("Dumbbell Curl", .biceps, [.forearms], .dumbbell),
            e("Cable Triceps Pushdown", .triceps, [], .cable),
            e("Skull Crusher", .triceps, [.forearms], .barbell),
            e("Hammer Curl", .biceps, [.forearms], .dumbbell),
            e("Bench Dip", .triceps, [.chest, .frontDelts], .bodyweight),
            e("Plank", .abs, [.obliques], .bodyweight),
            e("Cable Crunch", .abs, [], .cable),
            e("Hanging Leg Raise", .abs, [.obliques], .bodyweight),
            e("Machine Crunch", .abs, [], .machine),
            e("Russian Twist", .obliques, [.abs], .dumbbell),
            e("Mountain Climber", .abs, [.cardio, .quads], .bodyweight),
            e("Treadmill Run", .cardio, [.quads, .hamstrings, .calves], .machine),
            e("Rowing Machine", .cardio, [.lats, .quads, .hamstrings], .machine),
            e("Jump Rope", .cardio, [.calves], .bodyweight),
            e("Bike Sprint", .cardio, [.quads, .hamstrings], .machine),
            e("Burpee", .cardio, [.chest, .quads, .frontDelts], .bodyweight)
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

    static func makeWeekPlan(plans: [WorkoutPlan], calendar: Calendar = .current, today: Date = .now) -> [WeekPlanDay] {
        guard plans.isEmpty == false else { return [] }
        let start = startOfWeek(containing: today, calendar: calendar)
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            switch offset {
            case 1, 3, 5:
                return WeekPlanDay(date: date, workoutPlan: plans[offset % plans.count])
            case 0, 6:
                return WeekPlanDay(date: date, isRestDay: true)
            default:
                return nil
            }
        }
    }

    private static func seedWeekPlanIfNeeded(in context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<WeekPlanDay>())) ?? 0
        guard existing == 0 else { return }
        let plans = (try? context.fetch(FetchDescriptor<WorkoutPlan>())) ?? []
        makeWeekPlan(plans: plans).forEach { context.insert($0) }
        try? context.save()
    }

    static func startOfWeek(containing date: Date, calendar: Calendar = .current) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let daysFromWeekStart = (weekday - calendar.firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: -daysFromWeekStart, to: startOfDay) ?? startOfDay
    }

    private static func e(_ name: String, _ primary: MuscleGroup, _ secondary: [MuscleGroup], _ equipment: EquipmentType) -> Exercise {
        Exercise(name: name, primaryMuscle: primary, secondaryMuscles: secondary, equipment: equipment, instructions: "Use controlled form and full range of motion.")
    }
}
