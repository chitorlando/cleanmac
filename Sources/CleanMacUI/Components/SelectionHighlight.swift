import SwiftUI

/// Rounded background that marks the selected row with the feature's colors.
///
/// Used by ``SelectableRowStyle``, and also usable as a `List` row background.
public struct SelectionHighlight: View {
    private let isSelected: Bool
    private let isPressed: Bool
    private let theme: FeatureTheme
    @State private var isHovered = false

    public init(isSelected: Bool, isPressed: Bool = false, theme: FeatureTheme) {
        self.isSelected = isSelected
        self.isPressed = isPressed
        self.theme = theme
    }

    public var body: some View {
        shape
            .fill(fill)
            .overlay(shape.strokeBorder(isSelected ? theme.primary.opacity(0.55) : .clear, lineWidth: 1))
            .onHover { isHovered = $0 }
            .animation(.snappy(duration: 0.15), value: isSelected)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 10)
    }

    private var fill: AnyShapeStyle {
        if isSelected {
            AnyShapeStyle(theme.gradient.opacity(0.32))
        } else if isPressed {
            AnyShapeStyle(Color.white.opacity(0.08))
        } else if isHovered {
            AnyShapeStyle(Color.white.opacity(0.04))
        } else {
            AnyShapeStyle(Color.clear)
        }
    }
}
