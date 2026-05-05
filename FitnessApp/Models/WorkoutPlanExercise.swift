import Foundation
import SwiftData

@Model
final class WorkoutPlanExercise {
    @Attribute(.unique) var id: UUID
    var exercise: Exercise?
    var sets: Int
    var repsText: String
    var restSeconds: Int
    var orderIndex: Int

    init(
        id: UUID = UUID(),
        exercise: Exercise?,
        sets: Int,
        repsText: String,
        restSeconds: Int,
        orderIndex: Int
    ) {
        self.id = id
        self.exercise = exercise
        self.sets = sets
        self.repsText = repsText
        self.restSeconds = restSeconds
        self.orderIndex = orderIndex
    }
}
