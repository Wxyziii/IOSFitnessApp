import SwiftUI

struct MuscleMapView: View {
    let trainedGroups: Set<MuscleGroup>

    var body: some View {
        HStack(spacing: 28) {
            diagram(title: "Front", front: true)
            diagram(title: "Back", front: false)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Body diagram showing trained muscle groups")
    }

    private func diagram(title: String, front: Bool) -> some View {
        ZStack {
            Capsule().fill(Color.white.opacity(0.10)).frame(width: 44, height: 86).offset(y: -20)
            Circle().stroke(Color.white.opacity(0.28), lineWidth: 2).frame(width: 34, height: 34).offset(y: -88)
            muscle(.chest, width: 74, height: 42, x: 0, y: -48, show: front)
            muscle(.back, width: 74, height: 72, x: 0, y: -38, show: !front)
            muscle(.shoulders, width: 34, height: 34, x: -52, y: -56, show: true)
            muscle(.shoulders, width: 34, height: 34, x: 52, y: -56, show: true)
            muscle(.arms, width: 22, height: 78, x: -70, y: 0, show: true)
            muscle(.arms, width: 22, height: 78, x: 70, y: 0, show: true)
            muscle(.abs, width: 44, height: 64, x: 0, y: 10, show: front)
            muscle(.legs, width: 28, height: 96, x: -24, y: 86, show: true)
            muscle(.legs, width: 28, height: 96, x: 24, y: 86, show: true)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
                .offset(y: 150)
        }
        .frame(width: 150, height: 320)
    }

    private func muscle(_ group: MuscleGroup, width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat, show: Bool) -> some View {
        RoundedRectangle(cornerRadius: min(width, height) / 2, style: .continuous)
            .fill(show && trainedGroups.contains(group) ? AppTheme.green.opacity(0.75) : Color.white.opacity(0.08))
            .overlay {
                RoundedRectangle(cornerRadius: min(width, height) / 2, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            }
            .frame(width: width, height: height)
            .offset(x: x, y: y)
    }
}

typealias BodyDiagramView = MuscleMapView
