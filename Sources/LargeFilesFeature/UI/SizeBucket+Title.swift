import CleanMacUI
import Foundation

extension SizeBucket {
    /// Name of the range, starting at the smallest size the scan looks for, such as “50 MB to 100 MB”.
    func title(forMinimumSize minimumSize: Int64) -> String {
        let lower = lowerLimit(forMinimumSize: minimumSize).formattedByteCount
        guard let upperLimit else {
            return String(
                localized: "More than \(lower)",
                bundle: .module,
                comment: "Size filter for the largest files. The argument is a size, such as “1 GB”."
            )
        }
        return String(
            localized: "\(lower) to \(upperLimit.formattedByteCount)",
            bundle: .module,
            comment: "Size filter: files from one size up to another. The arguments are sizes, such as “50 MB” and “100 MB”."
        )
    }
}
