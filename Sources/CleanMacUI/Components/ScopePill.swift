import SwiftUI

/// Pill shown while a screen is limited to part of what it can show, such as one folder or
/// the items of one app: what it is limited to, with more details as a tooltip, and a button
/// that removes the limit.
///
/// It has the colors of `StatusBadge`, which can't hold an icon or a button. The label stays
/// on one line and is cut in the middle when it doesn't fit, so the pill is never wider than
/// the room it gets, such as in the smallest window.
public struct ScopePill: View {
    private static let maximumWidth: CGFloat = 420
    /// Side of the area that takes the click on the button, larger than its symbol.
    private static let buttonSize: CGFloat = 20

    private let symbolName: String
    private let label: Text
    private let help: Text
    private let clearTitle: Text
    private let theme: FeatureTheme
    private let onClear: () -> Void

    /// - Parameters:
    ///   - symbolName: Symbol in front of the label, for the kind of limit.
    ///   - label: What the screen is limited to, such as “Only in: Downloads”.
    ///   - help: Tooltip of the label, such as the full path of the folder.
    ///   - clearTitle: Tooltip and accessibility label of the button, which says what it shows instead.
    ///   - onClear: Called by the button of the pill, to remove the limit.
    public init(
        symbolName: String,
        label: Text,
        help: Text,
        clearTitle: Text,
        theme: FeatureTheme,
        onClear: @escaping () -> Void
    ) {
        self.symbolName = symbolName
        self.label = label
        self.help = help
        self.clearTitle = clearTitle
        self.theme = theme
        self.onClear = onClear
    }

    public var body: some View {
        HStack(spacing: 6) {
            labelView
            clearButton
        }
        .font(.callout.weight(.medium))
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 3)
        .background(theme.primary.opacity(0.16), in: .pill)
        .overlay(Capsule.pill.strokeBorder(theme.primary.opacity(0.35), lineWidth: 1))
        .frame(maxWidth: Self.maximumWidth)
    }

    private var labelView: some View {
        HStack(spacing: 6) {
            Image(systemName: symbolName)
                .accessibilityHidden(true)
            label
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .foregroundStyle(theme.primary)
        .help(help)
        .accessibilityElement(children: .combine)
    }

    private var clearButton: some View {
        Button(action: onClear) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
                .frame(width: Self.buttonSize, height: Self.buttonSize)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .help(clearTitle)
        .accessibilityLabel(clearTitle)
    }
}
