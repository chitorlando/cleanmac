import LoginItemsFeature
import Testing

struct LoginItemSectionTests {
    @Test func groupsByScopeWithTheUserFirst() {
        let sections = LoginItemSection.sections(of: [
            loginItem("shared", scope: .allUsers),
            loginItem("mine")
        ])

        #expect(sections.map(\.scope) == [.currentUser, .allUsers])
        #expect(sections.map { $0.items.map(\.job.label) } == [["mine"], ["shared"]])
    }

    @Test func leavesOutScopesWithoutItems() {
        #expect(LoginItemSection.sections(of: [loginItem("shared", scope: .allUsers)]).map(\.scope) == [.allUsers])
        #expect(LoginItemSection.sections(of: []).isEmpty)
    }

    @Test func listsOrphanedItemsFirstThenByName() {
        let section = LoginItemSection(scope: .currentUser, items: [
            loginItem("com.b", owner: "Beta"),
            loginItem("com.z", isOrphaned: true),
            loginItem("com.a", owner: "alpha"),
            loginItem("com.c", isOrphaned: true)
        ])

        #expect(section.items.map(\.displayName) == ["com.c", "com.z", "alpha", "Beta"])
    }
}
