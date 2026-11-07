import SwiftUI

/// Rounded search box with a magnifying glass and a button to clear the text.
public struct SearchField: View {
    @Binding private var text: String
    private let prompt: Text
    private let theme: FeatureTheme
    @FocusState private var isFocused: Bool

    /// - Parameter prompt: Placeholder shown while the field is empty, such as “Search apps”.
    public init(text: Binding<String>, prompt: Text, theme: FeatureTheme) {
        _text = text
        self.prompt = prompt
        self.theme = theme
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(text: $text, prompt: prompt) { prompt }
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onExitCommand(perform: clear)

            if !text.isEmpty {
                clearButton
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Palette.cardFill, in: .capsule)
        .overlay(Capsule().strokeBorder(borderStyle, lineWidth: 1))
        .tint(theme.primary)
        .animation(.snappy(duration: 0.15), value: isFocused)
    }

    private var clearButton: some View {
        Button(action: clear) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help(clearLabel)
        .accessibilityLabel(clearLabel)
    }

    private var clearLabel: Text {
        Text("Clear Search", bundle: .module, comment: "Button that empties a search field.")
    }

    private var borderStyle: Color {
        isFocused ? theme.primary.opacity(0.7) : Palette.cardStroke
    }

    private func clear() {
        text = ""
    }
}
