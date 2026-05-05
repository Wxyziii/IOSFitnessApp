import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String?
    let actionTitle: String?
    let action: (() -> Void)?
    @ViewBuilder var content: Content

    init(_ title: String? = nil, actionTitle: String? = nil, action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if title != nil || actionTitle != nil {
                HStack {
                    if let title {
                        Text(title).font(.headline)
                    }
                    Spacer()
                    if let actionTitle, let action {
                        Button(actionTitle, action: action)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.green)
                    }
                }
            }
            content
        }
        .cardStyle()
    }
}
