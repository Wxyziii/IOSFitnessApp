import Foundation
import SwiftData

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case abs = "Abs"
    case cardio = "Cardio"
    case glutes = "Glutes"
    case calves = "Calves"

    var id: String { rawValue }

    static let visibleFilters: [MuscleGroup] = [.chest, .back, .legs, .shoulders, .arms, .abs, .cardio]
    static let chartGroups: [MuscleGroup] = [.chest, .back, .arms, .legs, .shoulders, .abs]
}

enum EquipmentType: String, CaseIterable, Codable, Identifiable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case cable = "Cable"
    case machine = "Machine"
    case bodyweight = "Bodyweight"

    var id: String { rawValue }
}

enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        Exercise.self,
        WorkoutPlan.self,
        WorkoutPlanExercise.self,
        WorkoutSession.self,
        ExerciseSet.self,
        Achievement.self
    ]

    static let schema = Schema(models)
}
