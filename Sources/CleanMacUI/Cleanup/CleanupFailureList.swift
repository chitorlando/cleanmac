import CleanMacCore
import SwiftUI

/// Items that could not be removed, why in plain words, and where to go from there.
///
/// When macOS protected any of them, a button opens the Full Disk Access settings, which
/// lets CleanMac move such items on the next try. When CleanMac wasn't allowed to control
/// Finder, another one opens the Automation settings, where the user allows it.
public struct CleanupFailureList: View {
    private static let maxListHeight: CGFloat = 160
    /// Height the list keeps in a short window, where it scrolls instead of pushing the rest off screen.
    private static let minListHeight: CGFloat = 48

    private let failures: [CleanupFailure]
    @State private var listHeight: CGFloat = 0

    public init(failures: [CleanupFailure]) {
        self.failures = failures
    }

    public var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
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

                // Hugs short lists, and scrolls once they outgrow the maximum height or the window.
                ScrollView {
                    rows
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { listHeight = $0 }
                }
                .scrollBouncesOnlyWhenContentOverflows()
                .frame(minHeight: min(listHeight, Self.minListHeight), maxHeight: min(listHeight, Self.maxListHeight))

                if failures.includesProtectedItems {
                    FullDiskAccessSettingsButton()
                        .foregroundStyle(.tint)
                }
                if failures.includesFinderAutomationDenials {
                    AutomationSettingsButton()
                        .foregroundStyle(.tint)
                }
            }
        }
    }

    private var rows: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(failures, id: \.item.id) { failure in
                CleanupFailureRow(failure: failure)
            }
        }
        .padding(.trailing, 4)
    }
}
