@testable import MaintenanceFeature
import Foundation
import Testing

struct MaintenanceTaskKindTests {
    private static let bootOnly = MaintenanceEnvironment(spotlightVolumes: [URL(filePath: "/")])

    @Test func onlySystemWideTasksNeedAnAdministrator() {
        let administratorTasks = MaintenanceTaskKind.allCases.filter { $0.privilege == .administrator }

        #expect(administratorTasks == [.flushDNS, .freeMemory, .reindexSpotlight])
    }

    @Test(arguments: MaintenanceTaskKind.allCases)
    func everyTaskRunsAtLeastOneAbsoluteCommand(task: MaintenanceTaskKind) {
        let commands = task.commands(in: Self.bootOnly)

        #expect(!commands.isEmpty)
        #expect(commands.allSatisfy { $0.executable.path.hasPrefix("/") })
    }

    /// Only checks that the tools exist; running them would change the system.
    @Test(arguments: MaintenanceTaskKind.allCases)
    func everyToolIsInstalled(task: MaintenanceTaskKind) {
        for command in task.commands(in: Self.bootOnly) {
            #expect(FileManager.default.isExecutableFile(atPath: command.executable.path))
        }
    }

    @Test func flushesDNSInTwoSteps() {
        #expect(MaintenanceTaskKind.flushDNS.commands(in: Self.bootOnly).map(\.commandLine) == [
            "/usr/bin/dscacheutil -flushcache",
            "/usr/bin/killall -HUP mDNSResponder"
        ])
    }

    @Test func reindexesTheStartupVolume() {
        #expect(MaintenanceTaskKind.reindexSpotlight.commands(in: Self.bootOnly).map(\.commandLine) == [
            "/usr/bin/mdutil -E /"
        ])
    }

    @Test func reindexesEveryVolumeOfTheEnvironment() {
        let environment = MaintenanceEnvironment(spotlightVolumes: [
            URL(filePath: "/"),
            URL(filePath: "/Volumes/Mac Data/")
        ])

        #expect(MaintenanceTaskKind.reindexSpotlight.commands(in: environment).map(\.commandLine) == [
            "/usr/bin/mdutil -E / '/Volumes/Mac Data'"
        ])
    }
}
