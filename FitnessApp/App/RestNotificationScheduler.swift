import Foundation
import UserNotifications

struct RestNotificationRequest: Equatable {
    let identifier: String
    let title: String
    let body: String
    let seconds: Int
}

@MainActor
protocol RestNotificationScheduling {
    func requestPermissionIfNeeded() async
    func scheduleRestComplete(after seconds: Int) async
    func cancelRestNotifications()
}

@MainActor
final class RestNotificationScheduler: RestNotificationScheduling {
    static let restIdentifier = "rest-complete"

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    static func makeRequest(seconds: Int) -> RestNotificationRequest {
        RestNotificationRequest(
            identifier: restIdentifier,
            title: "Rest complete",
            body: "Time for your next set.",
            seconds: max(seconds, 1)
        )
    }

    func requestPermissionIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleRestComplete(after seconds: Int) async {
        await requestPermissionIfNeeded()
        cancelRestNotifications()

        let request = Self.makeRequest(seconds: seconds)
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(request.seconds), repeats: false)
        let notification = UNNotificationRequest(identifier: request.identifier, content: content, trigger: trigger)
        try? await center.add(notification)
    }

    func cancelRestNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.restIdentifier])
    }
}
