import SwiftUI

/// When a file was last used, relative to today, such as “3 months ago”.
struct LastUsedText: View {
    let date: Date?

    var body: some View {
        Group {
            if let date {
                Text(date, format: .relative(presentation: .named))
            } else {
                Text("Unknown", bundle: .module, comment: "Shown instead of the last use date of a file when it isn't known.")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}
