import SwiftUI

/// Small colored capsule that labels a state, such as “Running”.
public struct StatusBadge: View {
    private let title: Text
    private let color: Color

    public init(_ title: Text, color: Color) {
        self.title = title
        self.color = color
    }

    public var body: some View {
        title
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.16), in: .capsule)
            .overlay(Capsule().strokeBorder(color.opacity(0.35), lineWidth: 1))
            .fixedSize()
    }
}
