import Foundation

enum StatsCalculator {
    static func totalReps(from sessions: [WorkoutSession]) -> Int {
        sessions.flatMap(\.completedSets).filter(\.completed).reduce(0) { $0 + $1.reps }
    }

    static func totalVolume(from sessions: [WorkoutSession]) -> Double {
        sessions.flatMap(\.completedSets).filter(\.completed).reduce(0) { $0 + ($1.weightKg * Double($1.reps)) }
    }

    static func maxWeight(from sessions: [WorkoutSession]) -> Double {
        sessions.flatMap(\.completedSets).map(\.weightKg).max() ?? 0
    }

    static func workoutCount(from sessions: [WorkoutSession]) -> Int {
        sessions.count
    }

    static func currentStreak(from sessions: [WorkoutSession], calendar: Calendar = .current, today: Date = .now) -> Int {
        let days = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        var cursor = calendar.startOfDay(for: today)
        if !days.contains(cursor), let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor), days.contains(yesterday) {
            cursor = yesterday
        }

        var count = 0
        while days.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    static func currentStreak(from sessions: [WorkoutSession], weekPlanDays: [WeekPlanDay], calendar: Calendar = .current, today: Date = .now) -> Int {
        let todayStart = calendar.startOfDay(for: today)
        let completedWorkoutDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        let planByDay = Dictionary(grouping: weekPlanDays) { calendar.startOfDay(for: $0.date) }
        guard planByDay[todayStart]?.first?.isPlanned == true else { return 0 }

        func isFulfilled(_ day: Date) -> Bool {
            guard let plan = planByDay[day]?.first, plan.isPlanned else { return false }
            if plan.isRestDay { return true }
            return completedWorkoutDays.contains(day)
        }

        var cursor = todayStart
        if !isFulfilled(cursor),
           let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
           isFulfilled(yesterday) {
            cursor = yesterday
        }

        var count = 0
        while isFulfilled(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    static func fulfilledWeekdayIndexes(from sessions: [WorkoutSession], weekPlanDays: [WeekPlanDay], calendar: Calendar = .current, today: Date = .now) -> Set<Int> {
        let completedWorkoutDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        let start = SampleDataSeeder.startOfWeek(containing: today, calendar: calendar)
        return Set((0..<7).compactMap { index in
            guard let date = calendar.date(byAdding: .day, value: index, to: start),
                  let plan = weekPlanDays.first(where: { calendar.isDate($0.date, inSameDayAs: date) }),
                  plan.isPlanned else { return nil }
            if plan.isRestDay || completedWorkoutDays.contains(calendar.startOfDay(for: date)) {
                return index
            }
            return nil
        })
    }

    static func muscleTotals(from sessions: [WorkoutSession]) -> [MuscleGroup: Double] {
        var totals: [MuscleGroup: Double] = [:]
        for set in sessions.flatMap(\.completedSets) where set.completed {
            guard let exercise = set.exercise else { continue }
            let volume = set.weightKg * Double(set.reps)
            totals[exercise.primaryMuscle, default: 0] += volume * MuscleMapRegionCatalog.primaryActivation
            for secondary in exercise.secondaryMuscleGroups {
                totals[secondary, default: 0] += volume * MuscleMapRegionCatalog.secondaryActivation
            }
        }
        return totals
    }

    static func lastTrainedDate(for muscle: MuscleGroup, sessions: [WorkoutSession]) -> Date? {
        sessions.filter { session in
            session.completedSets.contains { set in
                guard let exercise = set.exercise else { return false }
                return exercise.primaryMuscle == muscle || exercise.secondaryMuscleGroups.contains(muscle)
            }
        }
        .map(\.date)
        .max()
    }

    static func equipmentReps(from sessions: [WorkoutSession], equipment: EquipmentType) -> Int {
        sessions.flatMap(\.completedSets).filter { set in
            set.completed && set.exercise?.equipment == equipment
        }.reduce(0) { $0 + $1.reps }
    }

    static func dailyVolume(from sessions: [WorkoutSession], calendar: Calendar = .current) -> [DailyVolume] {
        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.date) }
        return grouped.map { day, sessions in
            DailyVolume(date: day, volume: totalVolume(from: sessions))
        }
        .sorted { $0.date < $1.date }
    }
}

struct DailyVolume: Identifiable {
    let id = UUID()
    let date: Date
    let volume: Double
}

struct MuscleShare: Identifiable {
    let id = UUID()
    let group: MuscleGroup
    let value: Double
}
