import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let refreshIntervalSeconds: TimeInterval = 60

    private let state = QuotaState()
    private var orbController: OrbWindowController?
    private var detailController: DetailPanelController?
    private var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let detailController = DetailPanelController(state: state)
        let orbController = OrbWindowController(
            state: state,
            onToggleDetail: { [weak detailController] anchor in
                detailController?.toggle(near: anchor)
            },
            onRefresh: { [weak state] in
                state?.refresh()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )

        self.detailController = detailController
        self.orbController = orbController
        orbController.show()

        state.refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Self.refreshIntervalSeconds, repeats: true) { [weak state] _ in
            Task { @MainActor in
                state?.refresh()
            }
        }
    }
}
