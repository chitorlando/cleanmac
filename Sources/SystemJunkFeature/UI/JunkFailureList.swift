import CleanMacCore
import CleanMacUI
import SwiftUI

/// Items that could not be removed and why.
struct JunkFailureList: View {
    let failures: [CleanupFailure]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("\(failures.count) elementos no se pudieron mover", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(.yellow)
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(failures, id: \.item.id) { failure in
                            Text("\(failure.item.name): \(failure.reason)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxHeight: 120)
            }
        }
    }
}
