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
        [
            SystemJunkModule.live(),
            UninstallerModule.live(),
            LargeFilesModule.live(),
            DiskMapModule.live(),
            DuplicatesModule.live(),
            MaintenanceModule.live()
        ]
    }
}
