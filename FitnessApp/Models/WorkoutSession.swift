import Foundation
import SwiftData

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var workoutPlan: WorkoutPlan?
    var durationMinutes: Int
    @Relationship(deleteRule: .cascade) var completedSets: [ExerciseSet]

    init(
        id: UUID = UUID(),
        date: Date,
        workoutPlan: WorkoutPlan?,
        durationMinutes: Int,
        completedSets: [ExerciseSet] = []
    ) {
        self.id = id
        self.date = date
        self.workoutPlan = workoutPlan
        self.durationMinutes = durationMinutes
        self.completedSets = completedSets
    }
}
