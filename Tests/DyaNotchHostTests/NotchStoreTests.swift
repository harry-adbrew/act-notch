import CoreGraphics
import DyaNotchKit
import Testing
@testable import DyaNotchHost

@MainActor
@Suite struct NotchStoreTests {
    private func store(notched: Bool = true) -> NotchStore {
        NotchStore(geometry: NotchGeometry(
            displayID: 1,
            screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 950),
            hardwareNotch: notched ? CGSize(width: 185, height: 32) : nil
        ))
    }

    private let activity = ActivityCandidate(pluginID: "timer", activity: LiveActivity(id: "t", priority: .normal))

    @Test func presentationPrecedence() {
        let store = store()
        #expect(store.presentation(primary: nil) == .closed)
        #expect(store.presentation(primary: activity) == .compact)

        store.peekPluginID = "timer"
        #expect(store.presentation(primary: activity) == .peek)

        store.mode = .expanded
        #expect(store.presentation(primary: activity) == .expanded)

        store.suspended = true
        #expect(store.presentation(primary: activity) == .hidden)
    }

    @Test func idlePillScreenIsHidden() {
        #expect(store(notched: false).presentation(primary: nil) == .hidden)
    }

    @Test func turnPageWrapsBothWays() {
        let store = store()
        store.pageIDs = ["spotify", "timer", "todo"]
        store.currentPage = "spotify"

        store.turnPage(by: -1)
        #expect(store.selectedPage == "todo")

        store.currentPage = "todo"
        store.turnPage(by: 1)
        #expect(store.selectedPage == "spotify")
    }
}
