import SwiftUI

struct StreakPill: View {
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Text("🔥")
            Text("\(count)")
                .font(.headline.weight(.bold))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(AppTheme.card, in: Capsule())
        .overlay(Capsule().stroke(AppTheme.cardStroke, lineWidth: 1))
        .accessibilityLabel("\(count) day streak")
    }
}
