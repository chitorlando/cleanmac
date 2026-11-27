import SwiftUI

/// The ring of a long action, such as moving items to the Trash or a review whose length is
/// unknown: it spins in the feature's colors over the breathing glow of a scan.
///
/// With Reduce Motion on, the ring and its glow stand still.
public struct BusyRing: View {
    private static let diameter: CGFloat = 88
    /// How far beyond the ring the particles of its glow set off from.
    private static let orbReach: CGFloat = 44

    private let theme: FeatureTheme

    public init(theme: FeatureTheme) {
        self.theme = theme
    }

    public var body: some View {
        IndeterminateProgressRing(theme: theme, lineWidth: 9)
            .scanningOrb(theme: theme, reach: Self.orbReach)
            .frame(width: Self.diameter, height: Self.diameter)
    }
}
