import SecurityFeature
import Testing

struct AutomaticUpdatesEvaluatorTests {
    /// macOS turns every option on until the user changes them, so the keys are often missing.
    @Test func treatsMissingKeysAsOn() {
        let check = AutomaticUpdatesEvaluator.check(preferences: [:])

        #expect(check == ProtectionCheck(kind: .automaticUpdates, state: .on))
    }

    @Test func ignoresKeysOfOtherOptions() {
        let preferences: [String: Any] = ["AutomaticallyInstallMacOSUpdates": false, "LastResultCode": 2]

        #expect(AutomaticUpdatesEvaluator.check(preferences: preferences).state == .on)
    }

    @Test func listsTheSecurityOptionsThatAreOffAsPartial() {
        let preferences: [String: Any] = [
            "AutomaticCheckEnabled": true,
            "CriticalUpdateInstall": false,
            "ConfigDataInstall": false
        ]

        let check = AutomaticUpdatesEvaluator.check(preferences: preferences)

        #expect(check.state == .partial)
        #expect(check.detail == .updateOptionsOff([.installSecurityResponses, .installSystemDataFiles]))
    }

    @Test func isOffWhenUpdatesAreNotCheckedFor() {
        let check = AutomaticUpdatesEvaluator.check(preferences: ["AutomaticCheckEnabled": false])

        #expect(check.state == .off)
        #expect(check.detail == .updateOptionsOff([.checkForUpdates]))
    }

    @Test func readsNumbersAndStringsWrittenInsteadOfBooleans() {
        let preferences: [String: Any] = ["AutomaticDownload": 0, "CriticalUpdateInstall": "YES", "ConfigDataInstall": 1]

        #expect(AutomaticUpdatesEvaluator.check(preferences: preferences).detail == .updateOptionsOff([.downloadUpdates]))
    }

    @Test func namesEachOptionAfterItsKey() {
        #expect(AutomaticUpdateOption.allCases.map(\.rawValue) == [
            "AutomaticCheckEnabled", "AutomaticDownload", "CriticalUpdateInstall", "ConfigDataInstall"
        ])
    }
}
