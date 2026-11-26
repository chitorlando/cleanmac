import SecurityFeature
import Testing

struct ProtectionStatusParserTests {
    @Test func readsFileVault() {
        #expect(ProtectionStatusParser.fileVault("FileVault is On.\n") == .on)
        #expect(ProtectionStatusParser.fileVault("FileVault is Off.\n") == .off)
        #expect(ProtectionStatusParser.fileVault("FileVault is Off.\nDeferred enablement appears to be active for user 'ana'.\n") == .off)
        #expect(ProtectionStatusParser.fileVault("Encryption in progress: Percent completed = 42\n") == .on)
        #expect(ProtectionStatusParser.fileVault("FileVault is On.\nDecryption in progress: Percent completed = 10\n") == .off)
        #expect(ProtectionStatusParser.fileVault("") == .unknown)
        #expect(ProtectionStatusParser.fileVault("Error: unable to read status") == .unknown)
    }

    @Test func readsTheFirewallByItsStateNumber() {
        #expect(ProtectionStatusParser.firewall("Firewall is enabled. (State = 1)\n") == .on)
        #expect(ProtectionStatusParser.firewall("Firewall is blocking all non-essential incoming connections. (State = 2)\n") == .on)
        #expect(ProtectionStatusParser.firewall("Firewall is disabled. (State = 0)\n") == .off)
    }

    @Test func readsTheFirewallByItsWordsWithoutAStateNumber() {
        #expect(ProtectionStatusParser.firewall("Firewall is enabled.\n") == .on)
        #expect(ProtectionStatusParser.firewall("Firewall is disabled.\n") == .off)
        #expect(ProtectionStatusParser.firewall("socketfilterfw: unknown option") == .unknown)
    }

    @Test func readsGatekeeper() {
        #expect(ProtectionStatusParser.gatekeeper("assessments enabled\n") == .on)
        #expect(ProtectionStatusParser.gatekeeper("assessments disabled\n") == .off)
        #expect(ProtectionStatusParser.gatekeeper("") == .unknown)
    }

    @Test func readsSystemIntegrityProtection() {
        #expect(ProtectionStatusParser.systemIntegrityProtection("System Integrity Protection status: enabled.\n") == .on)
        #expect(ProtectionStatusParser.systemIntegrityProtection("System Integrity Protection status: disabled.\n") == .off)
        #expect(ProtectionStatusParser.systemIntegrityProtection("csrutil: failed to read") == .unknown)
    }

    /// A custom configuration turns some parts off, whatever the first word says.
    @Test func readsACustomConfigurationOfSystemIntegrityProtectionAsPartial() {
        let custom = """
        System Integrity Protection status: unknown (Custom Configuration).

        Configuration:
        \tKext Signing: disabled
        \tFilesystem Protections: disabled
        \tDebugging Restrictions: enabled
        """
        #expect(ProtectionStatusParser.systemIntegrityProtection(custom) == .partial)
        #expect(ProtectionStatusParser.systemIntegrityProtection("System Integrity Protection status: enabled (Custom Configuration).") == .partial)
    }

    @Test func onlyStatesThatAreNotFullyOnNeedAttention() {
        #expect(!ProtectionState.on.needsAttention)
        #expect(!ProtectionState.unknown.needsAttention)
        #expect(ProtectionState.off.needsAttention)
        #expect(ProtectionState.partial.needsAttention)
        #expect(ProtectionState.outdated.needsAttention)
    }
}
