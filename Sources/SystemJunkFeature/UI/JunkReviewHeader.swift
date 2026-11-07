import CleanMacUI
import SwiftUI

/// Summary of how much junk was found.
struct JunkReviewHeader: View {
    let foundSize: Int64
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 6) {
            Text(foundSize.formattedByteCount)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(theme.gradient)
            Text("de basura encontrada. Revisa lo que quieres limpiar.")
                .foregroundStyle(.secondary)
        }
    }
}
