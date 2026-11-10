import SwiftUI

/// When a copy was created, such as “Created Mar 5, 2026”, to tell the original from later copies.
struct CreationDateText: View {
    let date: Date?

    var body: some View {
        if let date {
            Text(
                "Created \(date.formatted(date: .abbreviated, time: .omitted))",
                bundle: .module,
                comment: "Creation date of a copy, shown after its folder. The argument is a date, such as “Mar 5, 2026”."
            )
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
    }
}
