import SwiftUI

/// Translucent rounded container used to group content.
public struct GlassCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(16)
            .background(Palette.cardFill, in: .rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Palette.cardStroke, lineWidth: 1)
            )
    }
}
