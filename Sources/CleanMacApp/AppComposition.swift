import CleanMacUI
import DiskMapFeature
import DuplicatesFeature
import LargeFilesFeature
import MaintenanceFeature
import SystemJunkFeature
import UninstallerFeature

/// Composition root: the only place that knows every feature and its concrete dependencies.
@MainActor
enum AppComposition {
    static func makeModules() -> [any FeatureModule] {
        let uninstaller = UninstallerModule.live()
        return [
            SystemJunkModule.live(),
            uninstaller,
            LargeFilesModule.live(),
            DiskMapModule.live(uninstallerFeatureID: uninstaller.id),
            DuplicatesModule.live(),
            MaintenanceModule.live()
        ]
    }
}
