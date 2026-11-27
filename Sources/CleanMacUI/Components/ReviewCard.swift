import SwiftUI

/// One part of a review's results, such as the security review's: a titled card with its findings.
public struct ReviewCard<Content: View>: View {
    private let title: Text
    private let summary: Text
    private let content: Content

    /// - Parameters:
    ///   - title: What the part is about, such as “Apps”.
    ///   - summary: What it looked at, in a sentence.
    ///   - content: Its findings, or a line saying there are none.
    public init(title: Text, summary: Text, @ViewBuilder content: () -> Content) {
        self.title = title
        self.summary = summary
        self.content = content()
    }

    public var body: some View {
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
