import SwiftUI

struct WorkoutPlanRow: View {
    let plan: WorkoutPlan
    let accessoryText: String?

    var body: some View {
        HStack(spacing: 14) {
            IconTile(iconName: plan.iconName, color: AppTheme.color(for: plan.colorToken))
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.name)
                    .font(.headline)
                Text(plan.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(1)
                Text("\(plan.exercises.count) exercises")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
            if let accessoryText {
                Text(accessoryText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accessoryText == "Today" ? AppTheme.green : AppTheme.muted)
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(AppTheme.muted)
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
