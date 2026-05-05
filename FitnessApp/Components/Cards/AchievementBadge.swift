import SwiftUI

struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: achievement.iconName)
                .font(.title2.weight(.bold))
                .foregroundStyle(achievement.isUnlocked ? AppTheme.color(for: achievement.colorToken) : AppTheme.muted)
                .frame(width: 54, height: 54)
                .background(
                    Circle()
                        .stroke(achievement.isUnlocked ? AppTheme.color(for: achievement.colorToken) : AppTheme.cardStroke, lineWidth: 3)
                        .background(Circle().fill(AppTheme.card))
                )
            Text(achievement.title)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(achievement.subtitleText)
                .font(.caption2)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 96)
        .frame(minHeight: 138)
        .padding(10)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(achievement.isUnlocked ? 1 : 0.55)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.title), \(achievement.isUnlocked ? "unlocked" : "locked")")
    }
}
