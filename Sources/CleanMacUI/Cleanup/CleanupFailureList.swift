import CleanMacCore
import SwiftUI

/// Items that could not be removed and why.
public struct CleanupFailureList: View {
    private static let maxListHeight: CGFloat = 120

    private let failures: [CleanupFailure]
    @State private var listHeight: CGFloat = 0

    public init(failures: [CleanupFailure]) {
        self.failures = failures
    }

    public var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text(
                        "\(failures.count) items couldn’t be moved",
                        bundle: .module,
                        comment: "Title of the list of items that failed to move to the Trash."
                    )
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                }
                .font(.headline)
                .foregroundStyle(.yellow)

                // Hugs short lists and only scrolls once they outgrow the maximum height.
                ScrollView {
                    reasons
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { listHeight = $0 }
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(height: min(listHeight, Self.maxListHeight))
            }
        }
    }

    private var reasons: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(failures, id: \.item.id) { failure in
                Text(verbatim: "\(failure.item.name): \(failure.reason)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
