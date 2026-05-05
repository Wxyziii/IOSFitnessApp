import Foundation
import SwiftData

@Model
final class WorkoutPlan {
    @Attribute(.unique) var id: UUID
    var name: String
    var subtitle: String
    var createdAt: Date
    var iconName: String
    var colorToken: String
    @Relationship(deleteRule: .cascade) var exercises: [WorkoutPlanExercise]

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String,
        createdAt: Date = .now,
        iconName: String = "dumbbell.fill",
        colorToken: String = "green",
        exercises: [WorkoutPlanExercise] = []
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.createdAt = createdAt
        self.iconName = iconName
        self.colorToken = colorToken
        self.exercises = exercises
    }

    var orderedExercises: [WorkoutPlanExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}
