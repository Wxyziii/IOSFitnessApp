import SwiftUI

enum AppTheme {
    static let green = Color(red: 0.34, green: 0.86, blue: 0.42)
    static let orange = Color(red: 1.0, green: 0.62, blue: 0.16)
    static let blue = Color(red: 0.28, green: 0.52, blue: 1.0)
    static let purple = Color(red: 0.62, green: 0.25, blue: 1.0)
    static let card = Color.white.opacity(0.06)
    static let cardStroke = Color.white.opacity(0.10)
    static let muted = Color.white.opacity(0.62)
    static let background = LinearGradient(
        colors: [Color(red: 0.02, green: 0.04, blue: 0.05), Color(red: 0.04, green: 0.07, blue: 0.08)],
        startPoint: .top,
        endPoint: .bottom
    )

    static func color(for token: String) -> Color {
        switch token {
        case "green": green
        case "orange": orange
        case "blue": blue
        case "purple": purple
        case "red": .red
        case "yellow": .yellow
        default: green
        }
    }
}

extension View {
    func appScreen() -> some View {
        background(AppTheme.background.ignoresSafeArea())
    }

    func cardStyle() -> some View {
        padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            }
    }
}
