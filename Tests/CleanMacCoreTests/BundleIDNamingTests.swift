import CleanMacCore
import Testing

struct BundleIDNamingTests {
    @Test(arguments: ["com.apple.Safari", "com.apple.safari", "com.apple.Safari.SafeBrowsing", "COM.APPLE.SAFARI.Helper"])
    func takesTheIdentifierAndWhatExtendsItAfterADot(name: String) {
        #expect(name.isNamed(afterBundleID: "com.apple.Safari"))
    }

    @Test(arguments: ["com.apple.SafariTechnologyPreview", "com.apple", "Safari", "com.apple.Safari-old", ""])
    func leavesOutOtherNames(name: String) {
        #expect(!name.isNamed(afterBundleID: "com.apple.Safari"))
    }
}
