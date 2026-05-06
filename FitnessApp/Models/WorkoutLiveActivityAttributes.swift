import ActivityKit
import Foundation

struct WorkoutLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentExerciseName: String
        var currentSet: Int
        var totalSets: Int
        var restEndDate: Date?
        var isResting: Bool
        var elapsedWorkoutTime: TimeInterval
        var completedSets: Int
        var totalVolume: Double
    }

    var workoutName: String
}

