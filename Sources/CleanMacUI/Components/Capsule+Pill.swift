import SwiftUI

extension Shape where Self == Capsule {
    /// Capsule with perfectly round ends.
    ///
    /// The default capsule uses continuous corners, and stroking it with `strokeBorder`
    /// leaves hairline seams at both ends, visible on glowing buttons and fields.
    static var pill: Capsule { Capsule(style: .circular) }
}
