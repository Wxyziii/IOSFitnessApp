import Foundation
import SwiftData

@Model
final class ExerciseSet {
    @Attribute(.unique) var id: UUID
    var exercise: Exercise?
    var weightKg: Double
    var reps: Int
    var setIndex: Int
    var completed: Bool

    init(
        id: UUID = UUID(),
        exercise: Exercise?,
        weightKg: Double,
        reps: Int,
        setIndex: Int,
        completed: Bool = true
    ) {
        self.id = id
        self.exercise = exercise
        self.weightKg = weightKg
        self.reps = reps
        self.setIndex = setIndex
        self.completed = completed
    }
}
