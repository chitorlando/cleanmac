import SwiftUI

/// A checkmark drawn as a single stroke, from the end of its short arm to the tip of its long
/// one, so trimming it draws it the way a hand would. It sits in the middle of a round badge.
struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.minY + rect.height * 0.66))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.71, y: rect.minY + rect.height * 0.37))
        return path
    }
}
