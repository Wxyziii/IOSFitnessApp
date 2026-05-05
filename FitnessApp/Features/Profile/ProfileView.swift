import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Preferences") {
                    row("Units", value: "Metric", icon: "scalemass")
                    row("Theme", value: "Dark", icon: "moon.fill")
                }
                Section("Data") {
                    row("Data Reset", value: "Placeholder", icon: "trash")
                }
                Section("About") {
                    row("App Version", value: "1.0", icon: "info.circle")
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Profile")
            .appScreen()
        }
    }

    private func row(_ title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.green)
                .frame(width: 28)
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(AppTheme.muted)
        }
        .accessibilityElement(children: .combine)
    }
}
