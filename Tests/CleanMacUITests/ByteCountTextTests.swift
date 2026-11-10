@testable import CleanMacUI
import Foundation
import Testing

struct ByteCountTextTests {
    @Test(arguments: ["en_US", "es_ES"])
    func zeroIsWrittenWithDigits(localeID: String) {
        #expect(Int64(0).formattedByteCount(locale: Locale(identifier: localeID)) == "0 kB")
    }

    @Test func otherSizesKeepTheSystemFormat() {
        #expect(Int64(48_000).formattedByteCount(locale: Locale(identifier: "en_US")) == "48 kB")
        #expect(Int64(1_200_000_000).formattedByteCount(locale: Locale(identifier: "en_US")) == "1.2 GB")
        #expect(Int64(1_200_000_000).formattedByteCount(locale: Locale(identifier: "es_ES")) == "1,2 GB")
    }
}
