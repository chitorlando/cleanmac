@testable import MaintenanceFeature
import Foundation
import Testing

struct MaintenanceTaskKindTests {
    @Test func onlySystemWideTasksNeedAnAdministrator() {
        let administratorTasks = MaintenanceTaskKind.allCases.filter { $0.privilege == .administrator }

        #expect(administratorTasks == [.flushDNS, .freeMemory, .reindexSpotlight])
    }

    @Test(arguments: MaintenanceTaskKind.allCases)
    func everyTaskRunsAtLeastOneAbsoluteCommand(task: MaintenanceTaskKind) {
        #expect(!task.commands.isEmpty)
        #expect(task.commands.allSatisfy { $0.executable.path.hasPrefix("/") })
    }

    /// Only checks that the tools exist; running them would change the system.
    @Test(arguments: MaintenanceTaskKind.allCases)
    func everyToolIsInstalled(task: MaintenanceTaskKind) {
        for command in task.commands {
            #expect(FileManager.default.isExecutableFile(atPath: command.executable.path))
        }
    }

    @Test func flushesDNSInTwoSteps() {
        #expect(MaintenanceTaskKind.flushDNS.commands.map(\.commandLine) == [
            "/usr/bin/dscacheutil -flushcache",
            "/usr/bin/killall -HUP mDNSResponder"
        ])
    }
}
