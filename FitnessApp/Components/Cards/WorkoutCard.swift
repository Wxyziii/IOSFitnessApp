import SwiftUI

struct WorkoutCard: View {
    let plan: WorkoutPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                IconTile(iconName: plan.iconName, color: AppTheme.color(for: plan.colorToken))
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundStyle(AppTheme.muted)
            }
            Text(plan.name)
                .font(.headline)
            Text(plan.subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
            HStack {
                Label("\(plan.exercises.count) exercises", systemImage: "list.bullet")
                Spacer()
                Label("45 min", systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(AppTheme.muted)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
