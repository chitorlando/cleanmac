import CleanMacCore
import CoreServices
import Testing

struct PermissionStatusTests {
    @Test func readsTheAppleEventsAnswer() {
        #expect(PermissionStatus(appleEventsResult: noErr) == .granted)
        #expect(PermissionStatus(appleEventsResult: OSStatus(errAEEventNotPermitted)) == .denied)
        #expect(PermissionStatus(appleEventsResult: OSStatus(errAEEventWouldRequireUserConsent)) == .notDetermined)
    }

    @Test func saysNothingForOtherErrors() {
        #expect(PermissionStatus(appleEventsResult: OSStatus(procNotFound)) == nil)
    }

    @Test func linksToThePrivacyPanes() {
        #expect(PermissionSettingsPane.fullDiskAccess.url.absoluteString.hasSuffix("Privacy_AllFiles"))
        #expect(PermissionSettingsPane.automation.url.absoluteString.hasSuffix("Privacy_Automation"))
    }
}
