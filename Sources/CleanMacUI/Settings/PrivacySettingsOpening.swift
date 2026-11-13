/// Opens the panes of System Settings where the user grants CleanMac access.
public protocol PrivacySettingsOpening: Sendable {
    @MainActor func openFullDiskAccess()
}
