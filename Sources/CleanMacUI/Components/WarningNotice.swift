import SwiftUI

/// Orange banner with a warning sign, such as the one above partial results of a stopped scan.
public struct WarningNotice: View {
    private let message: Text

    /// - Parameter message: The warning, already localized by the feature that shows it.
    public init(_ message: Text) {
        self.message = message
    }

    public var body: some View {
        Label {
            message
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.callout.weight(.medium))
        .foregroundStyle(.orange)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.12), in: .rect(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.orange.opacity(0.3), lineWidth: 1))
    }
}
