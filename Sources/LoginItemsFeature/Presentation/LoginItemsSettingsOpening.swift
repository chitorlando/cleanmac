/// Opens the Login Items pane of System Settings, which also lists the items apps
/// register without a property list CleanMac could read.
@MainActor
public protocol LoginItemsSettingsOpening {
    func openLoginItemsSettings()
}
