import Foundation

struct RestTimerState: Equatable {
    var endDate: Date?
    var now: Date

    var remainingSeconds: Int {
        guard let endDate else { return 0 }
        return max(0, Int(ceil(endDate.timeIntervalSince(now))))
    }

    var isRunning: Bool {
        remainingSeconds > 0
    }

    var isComplete: Bool {
        endDate != nil && remainingSeconds == 0
    }

    static func endDate(durationSeconds: Int, now: Date = .now) -> Date {
        now.addingTimeInterval(TimeInterval(max(durationSeconds, 0)))
    }
}

