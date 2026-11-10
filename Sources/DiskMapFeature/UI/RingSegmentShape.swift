import SwiftUI

/// Slice of a ring between two angles, measured clockwise from the top,
/// and two radii given as fractions of the radius of the space it's drawn in.
struct RingSegmentShape: Shape {
    let startDegrees: Double
    let endDegrees: Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let start = Angle.degrees(startDegrees - 90)
        let end = Angle.degrees(endDegrees - 90)
        var path = Path()
        path.addArc(center: center, radius: radius * outerRadius, startAngle: start, endAngle: end, clockwise: false)
        path.addArc(center: center, radius: radius * innerRadius, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }
}
