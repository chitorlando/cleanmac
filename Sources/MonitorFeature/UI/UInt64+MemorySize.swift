import CleanMacUI
import Foundation

extension UInt64 {
    /// This many bytes of memory as text, such as "9,5 GB".
    ///
    /// Every amount of memory the monitor shows goes through here, so they all use the binary
    /// units Activity Monitor uses and a Mac with 16 GB reads "16 GB". Disk space keeps the
    /// decimal units Finder uses, with `formattedByteCount`.
    var formattedMemorySize: String {
        formattedMemorySize(locale: .autoupdatingCurrent)
    }

    func formattedMemorySize(locale: Locale) -> String {
        Int64(clamping: self).formattedMemoryByteCount(locale: locale)
    }
}
