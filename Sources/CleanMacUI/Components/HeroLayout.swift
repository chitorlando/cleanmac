import SwiftUI

/// A large icon with a title and a subtitle below it, centered: the header that introduces a
/// feature or reports what it did.
///
/// Title and subtitle wrap instead of truncating. They never get narrower than
/// `minimumTextWidth`: measured at a width near zero, wrapped text would report a
/// minimum height of thousands of points and the window could not fit on screen.
struct HeroLayout<Icon: View, Title: View>: View {
    private static var minimumTextWidth: CGFloat { 320 }

    private let subtitle: String
    private let icon: Icon
    private let title: Title

    /// - Parameters:
    ///   - icon: The large icon on top, which VoiceOver should skip.
    ///   - title: The title, which gets the font and the role of a header.
    init(subtitle: String, @ViewBuilder icon: () -> Icon, @ViewBuilder title: () -> Title) {
        self.subtitle = subtitle
        self.icon = icon()
        self.title = title()
    }

    var body: some View {
        VStack(spacing: 18) {
            icon

            title
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minWidth: Self.minimumTextWidth)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minWidth: Self.minimumTextWidth, maxWidth: 460)
        }
    }
}
