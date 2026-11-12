import CleanMacUI
import DiskMapFeature
import DuplicatesFeature
import LargeFilesFeature
import LoginItemsFeature
import MaintenanceFeature
import MonitorFeature
import SystemJunkFeature
import UninstallerFeature

/// Composition root: the only place that knows every feature and its concrete dependencies.
@MainActor
enum AppComposition {
    static func makeModules() -> [any FeatureModule] {
        let uninstaller = UninstallerModule.live()
        let diskMap = DiskMapModule.live(uninstallerFeatureID: uninstaller.id)
        return [
            SystemJunkModule.live(),
            uninstaller,
            LargeFilesModule.live(),
            diskMap,
            DuplicatesModule.live(),
            MaintenanceModule.live(),
            LoginItemsModule.live(),
            MonitorModule.live(diskMapFeatureID: diskMap.id)
        ]
    }
}
