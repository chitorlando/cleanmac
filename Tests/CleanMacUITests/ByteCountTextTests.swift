@testable import CleanMacUI
import Foundation
import Testing

struct ByteCountTextTests {
    /// The memory of a Mac sold with 16 GB.
    private let sixteenGigabytes: Int64 = 17_179_869_184
    private let english = Locale(identifier: "en_US")
    private let spanish = Locale(identifier: "es_ES")

    @Test(arguments: ["en_US", "es_ES"])
    func zeroIsWrittenWithDigits(localeID: String) {
        #expect(Int64(0).formattedByteCount(locale: Locale(identifier: localeID)) == "0 kB")
    }

    @Test func otherSizesKeepTheSystemFormat() {
        #expect(Int64(48_000).formattedByteCount(locale: english) == "48 kB")
        #expect(Int64(1_200_000_000).formattedByteCount(locale: english) == "1.2 GB")
        #expect(Int64(1_200_000_000).formattedByteCount(locale: spanish) == "1,2 GB")
    }

    @Test func sizesOfFilesAndDisksUseDecimalUnits() {
        #expect(sixteenGigabytes.formattedByteCount(locale: english) == "17.18 GB")
    }

    @Test func memoryUsesBinaryUnits() {
        #expect(sixteenGigabytes.formattedMemoryByteCount(locale: english) == "16 GB")
        #expect(Int64(536_870_912).formattedMemoryByteCount(locale: english) == "512 MB")
        #expect(Int64(1_610_612_736).formattedMemoryByteCount(locale: english) == "1.5 GB")
        #expect(Int64(1_610_612_736).formattedMemoryByteCount(locale: spanish) == "1,5 GB")
    }

    @Test(arguments: ["en_US", "es_ES"])
    func noMemoryIsWrittenWithDigits(localeID: String) {
        #expect(Int64(0).formattedMemoryByteCount(locale: Locale(identifier: localeID)) == "0 kB")
    }
}
