import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.green, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(.black)
        }
        .buttonStyle(.plain)
    }
}
