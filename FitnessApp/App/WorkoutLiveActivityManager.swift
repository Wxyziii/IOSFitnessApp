import ActivityKit
import Foundation

@MainActor
final class WorkoutLiveActivityManager {
    nonisolated(unsafe) private var activity: Activity<WorkoutLiveActivityAttributes>?

    func start(workoutName: String, state: WorkoutLiveActivityAttributes.ContentState) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            activity = try Activity.request(
                attributes: WorkoutLiveActivityAttributes(workoutName: workoutName),
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            activity = nil
        }
    }

    func update(_ state: WorkoutLiveActivityAttributes.ContentState) async {
        await activity?.update(ActivityContent(state: state, staleDate: nil))
    }

    func end(_ state: WorkoutLiveActivityAttributes.ContentState) async {
        await activity?.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
        activity = nil
    }
}
