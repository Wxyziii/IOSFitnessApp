import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let delta: String?
    let iconName: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.headline.weight(.bold))
                .minimumScaleFactor(0.8)
            if let delta {
                Text(delta)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
