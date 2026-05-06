import Foundation

enum WorkoutPRType: String, Codable {
    case weight
    case volume
    case reps
}

struct WorkoutPR: Identifiable, Equatable {
    let id = UUID()
    let exerciseName: String
    let type: WorkoutPRType
    let value: Double

    var message: String {
        switch type {
        case .weight:
            "\(exerciseName): New weight PR \(Int(value)) kg"
        case .volume:
            "\(exerciseName): New volume PR \(Int(value)) kg"
        case .reps:
            "\(exerciseName): New reps PR \(Int(value)) reps"
        }
    }
}

enum WorkoutPRDetector {
    static func detect(newSets: [ExerciseSet], previousSessions: [WorkoutSession]) -> [WorkoutPR] {
        let completed = newSets.filter(\.completed)
        let previousSets = previousSessions.flatMap(\.completedSets).filter(\.completed)
        var prs: [WorkoutPR] = []

        let grouped = Dictionary(grouping: completed) { $0.exercise?.name ?? "Unknown" }
        for (exerciseName, sets) in grouped {
            let previousForExercise = previousSets.filter { $0.exercise?.name == exerciseName }

            let newMaxWeight = sets.map(\.weightKg).max() ?? 0
            let oldMaxWeight = previousForExercise.map(\.weightKg).max() ?? 0
            if newMaxWeight > oldMaxWeight {
                prs.append(WorkoutPR(exerciseName: exerciseName, type: .weight, value: newMaxWeight))
            }

            let newMaxReps = sets.map(\.reps).max() ?? 0
            let oldMaxReps = previousForExercise.map(\.reps).max() ?? 0
            if newMaxReps > oldMaxReps {
                prs.append(WorkoutPR(exerciseName: exerciseName, type: .reps, value: Double(newMaxReps)))
            }

            let newVolume = sets.reduce(0) { $0 + ($1.weightKg * Double($1.reps)) }
            let oldBestVolume = previousBestSessionVolume(exerciseName: exerciseName, sessions: previousSessions)
            if newVolume > oldBestVolume {
                prs.append(WorkoutPR(exerciseName: exerciseName, type: .volume, value: newVolume))
            }
        }

        return prs.sorted { $0.message < $1.message }
    }

    private static func previousBestSessionVolume(exerciseName: String, sessions: [WorkoutSession]) -> Double {
        sessions.map { session in
            session.completedSets
                .filter { $0.completed && $0.exercise?.name == exerciseName }
                .reduce(0) { $0 + ($1.weightKg * Double($1.reps)) }
        }
        .max() ?? 0
    }
}

