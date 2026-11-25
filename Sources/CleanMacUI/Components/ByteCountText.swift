import Foundation

public extension Int64 {
    /// Human readable size of files and disks, such as "1,2 GB", in the decimal units Finder uses.
    ///
    /// Always written with digits: zero reads "0 kB" instead of the "Zero kB" that English spells out.
    var formattedByteCount: String {
        formattedByteCount(locale: .autoupdatingCurrent)
    }

    /// Human readable amount of memory, such as "1,5 GB", in the binary units Activity Monitor uses.
    ///
    /// Memory comes in powers of two: the 17,179,869,184 bytes of a Mac sold with 16 GB read
    /// "16 GB" here, and "17,18 GB" as the size of a file. Zero is written with digits as well.
    var formattedMemoryByteCount: String {
        formattedMemoryByteCount(locale: .autoupdatingCurrent)
    }

    func formattedMemoryByteCount(locale: Locale) -> String {
        formattedByteCount(style: .memory, locale: locale)
    }
}

extension Int64 {
    func formattedByteCount(style: ByteCountFormatStyle.Style = .file, locale: Locale) -> String {
        guard self != 0 else {
            return formatted(.byteCount(style: style, allowedUnits: .kb, spellsOutZero: false).locale(locale))
        }
        return formatted(.byteCount(style: style).locale(locale))
    }
}
