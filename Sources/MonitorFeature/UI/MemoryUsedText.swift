import SwiftUI

/// Memory in use out of the installed memory, such as “9 GB of 16 GB used”.
struct MemoryUsedText: View {
    let usage: MemoryUsage

    var body: some View {
        Text(
            "\(usage.used.formattedMemorySize) of \(usage.physical.formattedMemorySize) used",
            bundle: .module,
            comment: "Memory in use out of the installed memory. The arguments are sizes, such as “9 GB” and “16 GB”."
        )
    }
}
