import Foundation
import SwiftData

@Model
final class Achievement {
    @Attribute(.unique) var id: UUID
    var title: String
    var subtitleText: String
    var category: String
    var iconName: String
    var progress: Double
    var target: Double
    var earnedDate: Date?
    var colorToken: String

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        category: String,
        iconName: String,
        progress: Double,
        target: Double,
        earnedDate: Date? = nil,
        colorToken: String = "green"
    ) {
        self.id = id
        self.title = title
        self.subtitleText = subtitle
        self.category = category
        self.iconName = iconName
        self.progress = progress
        self.target = target
        self.earnedDate = earnedDate
        self.colorToken = colorToken
    }

    var isUnlocked: Bool {
        earnedDate != nil || progress >= target
    }
}
