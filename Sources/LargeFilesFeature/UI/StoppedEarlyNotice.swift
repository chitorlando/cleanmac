import SwiftUI

/// Warns that the list is incomplete because the user stopped the scan.
struct StoppedEarlyNotice: View {
    var body: some View {
        Label {
            Text(
                "The scan was stopped, so these results are incomplete.",
                bundle: .module,
                comment: "Warning shown above partial results after the user stopped the scan."
            )
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
