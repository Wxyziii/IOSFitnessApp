import SwiftUI

struct MuscleTag: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.green.opacity(0.13), in: Capsule())
            .foregroundStyle(AppTheme.green)
    }
}
