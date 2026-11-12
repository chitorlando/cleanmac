import SwiftUI

/// A share as a whole percentage, or a dash while it isn't known yet.
struct PercentText: View {
    let value: Double?

    var body: some View {
        if let value {
            Text(value, format: .percent.precision(.fractionLength(0)))
                .monospacedDigit()
        } else {
            Text(verbatim: "—")
                .foregroundStyle(.secondary)
        }
    }
}
