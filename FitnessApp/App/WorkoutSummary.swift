import Foundation

struct WorkoutSummary: Identifiable {
    let id = UUID()
    let workoutName: String
    let durationMinutes: Int
    let completedSets: [ExerciseSet]
    let prs: [WorkoutPR]

    var totalSets: Int {
        completedSets.filter(\.completed).count
    }

    var totalReps: Int {
        completedSets.filter(\.completed).reduce(0) { $0 + $1.reps }
    }

    var totalVolume: Double {
        completedSets.filter(\.completed).reduce(0) { $0 + ($1.weightKg * Double($1.reps)) }
    }

    var musclesTrained: [MuscleGroup] {
        let muscles = completedSets.compactMap(\.exercise).flatMap { exercise in
            [exercise.primaryMuscle] + exercise.secondaryMuscleGroups
        }
        return Array(Set(muscles)).sorted { $0.rawValue < $1.rawValue }
    }

    var muscleActivations: [MuscleGroup: Double] {
        var totals: [MuscleGroup: Double] = [:]
        for set in completedSets where set.completed {
            guard let exercise = set.exercise else { continue }
            let volume = set.weightKg * Double(set.reps)
            totals[exercise.primaryMuscle, default: 0] += volume * MuscleMapRegionCatalog.primaryActivation
            for secondary in exercise.secondaryMuscleGroups {
                totals[secondary, default: 0] += volume * MuscleMapRegionCatalog.secondaryActivation
            }
        }
        return totals
    }
}
