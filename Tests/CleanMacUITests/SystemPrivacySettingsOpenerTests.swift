@testable import CleanMacUI
import Testing

struct SystemPrivacySettingsOpenerTests {
    @Test func opensTheFullDiskAccessPane() {
        #expect(
            SystemPrivacySettingsOpener.fullDiskAccessURL.absoluteString
                == "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        )
    }
}
