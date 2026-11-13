import Testing
import UninstallerFeature

struct LeftoverProtectionTests {
    @Test func macOSProtectsAppContainers() {
        #expect(LeftoverKind.containers.isProtectedByMacOS)
        #expect(LeftoverKind.groupContainers.isProtectedByMacOS)
    }

    @Test(arguments: LeftoverKind.allCases.filter { $0 != .containers && $0 != .groupContainers })
    func otherLeftoversAreNotProtected(kind: LeftoverKind) {
        #expect(!kind.isProtectedByMacOS)
    }

    @Test func sectionsOfContainersAreProtectedButNotTheApp() {
        #expect(AppItemSection.Category.leftover(.containers).isProtectedByMacOS)
        #expect(!AppItemSection.Category.leftover(.caches).isProtectedByMacOS)
        #expect(!AppItemSection.Category.application.isProtectedByMacOS)
    }
}
