import SwiftUI

/// Badge, title and subtitle that report a task finished, such as a cleanup.
///
/// The badge grows out of the ring of the task that just ended, pops in and draws its
/// checkmark. When the task did everything it was asked to, a soft burst spreads around the
/// badge, once. The title can count up to what was done, with ``CountUpText``.
public struct SuccessHeader<Title: View>: View {
    /// The same as the ring of a busy view, which the badge grows out of.
    private static var badgeDiameter: CGFloat { 88 }

    private let subtitle: String
    private let theme: FeatureTheme
    private let celebrates: Bool
    private let title: Title

    /// - Parameters:
    ///   - celebrates: Whether a burst spreads around the badge: only when the task did
    ///     everything it was asked to, and something at all.
    ///   - title: What was done, such as “1.2 GB freed”.
    public init(
        subtitle: String,
        theme: FeatureTheme,
        celebrates: Bool = true,
        @ViewBuilder title: () -> Title
    ) {
        self.subtitle = subtitle
        self.theme = theme
        self.celebrates = celebrates
        self.title = title()
    }

    public var body: some View {
        HeroLayout(subtitle: subtitle) {
            SuccessBadge(theme: theme, diameter: Self.badgeDiameter, celebrates: celebrates)
        } title: {
            title
        }
    }
}
