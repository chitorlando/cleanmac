import CleanMacUI
import SwiftUI

/// One part of the review's results: a titled card with its findings.
struct SecurityCard<Content: View>: View {
    let title: Text
    let summary: Text
    let content: Content

    init(title: Text, summary: Text, @ViewBuilder content: () -> Content) {
        self.title = title
        self.summary = summary
        self.content = content()
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    title
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    summary
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Divider()
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
