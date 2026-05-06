import Foundation
import SwiftData

@Model
final class WeekPlanDay {
    @Attribute(.unique) var id: UUID
    var date: Date
    var isRestDay: Bool
    var workoutPlan: WorkoutPlan?

    init(
        id: UUID = UUID(),
        date: Date,
        isRestDay: Bool = false,
        workoutPlan: WorkoutPlan? = nil
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.isRestDay = isRestDay
        self.workoutPlan = workoutPlan
    }

    var isPlanned: Bool {
        isRestDay || workoutPlan != nil
    }
}
