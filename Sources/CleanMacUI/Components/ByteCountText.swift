import SwiftUI

public extension Int64 {
    /// Human readable size, such as "1,2 GB".
    ///
    /// Always written with digits: zero reads "0 kB" instead of the "Zero kB" that English spells out.
    var formattedByteCount: String {
        formattedByteCount(locale: .autoupdatingCurrent)
    }
}

extension Int64 {
    func formattedByteCount(locale: Locale) -> String {
        guard self != 0 else {
            return formatted(.byteCount(style: .file, allowedUnits: .kb, spellsOutZero: false).locale(locale))
        }
        return formatted(.byteCount(style: .file).locale(locale))
    }
}
