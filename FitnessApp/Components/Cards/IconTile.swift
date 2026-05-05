import SwiftUI

struct IconTile: View {
    let iconName: String
    let color: Color

    var body: some View {
        Image(systemName: iconName)
            .font(.title2.weight(.bold))
            .foregroundStyle(color)
            .frame(width: 54, height: 54)
            .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityHidden(true)
    }
}
