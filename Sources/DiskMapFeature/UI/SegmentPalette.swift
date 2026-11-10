import SwiftUI

/// Colors of the disk map: one hue per branch of the innermost ring, fading toward the
/// outer rings, and gray for the small items counted together.
enum SegmentPalette {
    private static let hues: [Color] = [
        Color(red: 0.36, green: 0.62, blue: 1.00),
        Color(red: 0.30, green: 0.87, blue: 0.62),
        Color(red: 1.00, green: 0.56, blue: 0.30),
        Color(red: 0.80, green: 0.48, blue: 1.00),
        Color(red: 1.00, green: 0.75, blue: 0.25),
        Color(red: 0.95, green: 0.36, blue: 0.52),
        Color(red: 0.30, green: 0.80, blue: 0.90),
        Color(red: 0.62, green: 0.82, blue: 0.32)
    ]
    static let other = Color(white: 0.5)

    static func color(forBranch branch: Int) -> Color {
        hues[branch % hues.count]
    }

    static func color(for segment: RingSegment) -> Color {
        let base = segment.node == nil ? other : color(forBranch: segment.branch)
        return base.opacity(1 - Double(segment.ring) * 0.22)
    }
}
