import SwiftData
import SwiftUI

struct WeekPlannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutPlan.createdAt) private var plans: [WorkoutPlan]
    @Query(sort: \WeekPlanDay.date) private var weekPlanDays: [WeekPlanDay]

    private let calendar = Calendar.current

    private var weekDates: [Date] {
        let start = SampleDataSeeder.startOfWeek(containing: .now, calendar: calendar)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionCard("Streak Rules") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Plan every day as workout or rest.", systemImage: "calendar")
                            Label("Unplanned days break streak.", systemImage: "exclamationmark.triangle")
                            Label("Missed planned workouts break streak.", systemImage: "xmark.circle")
                        }
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                    }

                    SectionCard("This Week") {
                        VStack(spacing: 12) {
                            ForEach(weekDates, id: \.self) { date in
                                WeekPlanRow(
                                    date: date,
                                    plan: plan(for: date),
                                    workoutPlans: plans,
                                    setRest: { setRest(on: date) },
                                    setWorkout: { workoutPlan in setWorkout(workoutPlan, on: date) },
                                    clear: { clear(date) }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Plan Your Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .appScreen()
        }
    }

    private func plan(for date: Date) -> WeekPlanDay? {
        weekPlanDays.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func setRest(on date: Date) {
        let entry = plan(for: date) ?? WeekPlanDay(date: date)
        entry.date = calendar.startOfDay(for: date)
        entry.isRestDay = true
        entry.workoutPlan = nil
        if plan(for: date) == nil {
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }

    private func setWorkout(_ workoutPlan: WorkoutPlan, on date: Date) {
        let entry = plan(for: date) ?? WeekPlanDay(date: date)
        entry.date = calendar.startOfDay(for: date)
        entry.isRestDay = false
        entry.workoutPlan = workoutPlan
        if plan(for: date) == nil {
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }

    private func clear(_ date: Date) {
        if let entry = plan(for: date) {
            modelContext.delete(entry)
            try? modelContext.save()
        }
    }
}

private struct WeekPlanRow: View {
    let date: Date
    let plan: WeekPlanDay?
    let workoutPlans: [WorkoutPlan]
    let setRest: () -> Void
    let setWorkout: (WorkoutPlan) -> Void
    let clear: () -> Void

    private var title: String {
        date.formatted(.dateTime.weekday(.wide))
    }

    private var subtitle: String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    private var status: String {
        if plan?.isRestDay == true { return "Rest day" }
        if let workoutName = plan?.workoutPlan?.name { return workoutName }
        return "Not planned"
    }

    private var statusColor: Color {
        plan?.isPlanned == true ? AppTheme.green : AppTheme.orange
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(status)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .multilineTextAlignment(.trailing)
                Menu {
                    Button("Rest day", action: setRest)
                    ForEach(workoutPlans) { workoutPlan in
                        Button(workoutPlan.name) {
                            setWorkout(workoutPlan)
                        }
                    }
                    if plan != nil {
                        Divider()
                        Button("Clear day", role: .destructive, action: clear)
                    }
                } label: {
                    Label("Set day", systemImage: "slider.horizontal.3")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.green)
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(status)")
    }
}
