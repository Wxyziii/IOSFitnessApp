import ActivityKit
import SwiftUI
import WidgetKit

@main
struct WorkoutLiveActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivityWidget()
    }
}

struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutLiveActivityAttributes.self) { context in
            LockScreenWorkoutActivityView(context: context)
                .activityBackgroundTint(Color(red: 0.02, green: 0.04, blue: 0.05))
                .activitySystemActionForegroundColor(.green)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text(context.attributes.workoutName)
                            .font(.headline)
                        Text(context.state.currentExerciseName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("\(context.state.completedSets)/\(context.state.totalSets)")
                            .font(.headline)
                        Text("\(Int(context.state.totalVolume)) kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label("Set \(context.state.currentSet)", systemImage: "dumbbell.fill")
                        Spacer()
                        timerText(context.state)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(.green)
            } compactTrailing: {
                timerText(context.state)
                    .font(.caption2)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: context.state.isResting ? "timer" : "figure.strengthtraining.traditional")
                    .foregroundStyle(.green)
            }
        }
    }

    @ViewBuilder
    private func timerText(_ state: WorkoutLiveActivityAttributes.ContentState) -> some View {
        if state.isResting, let restEndDate = state.restEndDate {
            Text(timerInterval: Date()...restEndDate, countsDown: true)
                .monospacedDigit()
        } else {
            Text(Self.elapsedText(state.elapsedWorkoutTime))
                .monospacedDigit()
        }
    }

    private static func elapsedText(_ seconds: TimeInterval) -> String {
        let value = max(0, Int(seconds))
        return "\(value / 60):\((value % 60).formatted(.number.precision(.integerLength(2))))"
    }
}

private struct LockScreenWorkoutActivityView: View {
    let context: ActivityViewContext<WorkoutLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(context.attributes.workoutName)
                    .font(.headline)
                Spacer()
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(.green)
            }
            Text(context.state.currentExerciseName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Label("\(context.state.completedSets)/\(context.state.totalSets) sets", systemImage: "checkmark.circle.fill")
                Spacer()
                Text("\(Int(context.state.totalVolume)) kg")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.green)
        }
        .padding()
    }
}

