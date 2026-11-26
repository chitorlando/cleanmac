import Foundation
@testable import MonitorFeature
import Testing

/// Memory reads as in Activity Monitor, which counts it in binary units.
struct MemorySizeTests {
    private static let gigabyte: UInt64 = 1_073_741_824
    private let english = Locale(identifier: "en_US")

    @Test(arguments: [(UInt64(8), "8 GB"), (16, "16 GB"), (64, "64 GB")])
    func readsTheInstalledMemoryAsItIsSold(gigabytes: UInt64, text: String) {
        #expect((gigabytes * Self.gigabyte).formattedMemorySize(locale: english) == text)
    }

    @Test func readsPartsOfAGigabyteInBinaryUnits() {
        #expect((Self.gigabyte / 2).formattedMemorySize(locale: english) == "512 MB")
        #expect((Self.gigabyte * 19 / 2).formattedMemorySize(locale: english) == "9.5 GB")
        #expect((Self.gigabyte * 19 / 2).formattedMemorySize(locale: Locale(identifier: "es_ES")) == "9,5 GB")
    }

    @Test func writesNoMemoryWithDigits() {
        #expect(UInt64(0).formattedMemorySize(locale: english) == "0 kB")
    }

    @Test func takesAmountsTooLargeToCountAsTheLargestOne() {
        #expect(UInt64.max.formattedMemorySize(locale: english) == UInt64(Int64.max).formattedMemorySize(locale: english))
    }
}
