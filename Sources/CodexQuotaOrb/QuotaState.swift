import Combine
import Foundation

@MainActor
final class QuotaState: ObservableObject {
    enum Status: Equatable {
        case idle
        case refreshing
        case ready
        case stale(String)
        case unavailable(String)
    }

    @Published private(set) var snapshot: QuotaSnapshot?
    @Published private(set) var history: [QuotaSnapshot] = []
    @Published private(set) var status: Status = .idle

    private let provider: CodexQuotaProvider
    private let store: QuotaHistoryStore

    init(provider: CodexQuotaProvider = CodexQuotaProvider(), store: QuotaHistoryStore) {
        self.provider = provider
        self.store = store
        self.history = (try? store.recentSamples(limit: 48).reversed()) ?? []
        self.snapshot = history.last
        if snapshot != nil {
            self.status = .ready
        }
    }

    convenience init() {
        let store = (try? QuotaHistoryStore()) ?? (try! QuotaHistoryStore(databaseURL: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("codex-quota-orb-fallback.sqlite")))
        self.init(store: store)
    }

    func refresh() {
        status = .refreshing
        Task.detached { [provider, store] in
            do {
                let snapshot = try provider.fetch()
                try store.save(snapshot)
                let history = try store.recentSamples(limit: 48).reversed()
                await MainActor.run {
                    self.snapshot = snapshot
                    self.history = Array(history)
                    self.status = .ready
                }
            } catch {
                await MainActor.run {
                    let message = String(describing: error)
                    self.status = self.snapshot == nil ? .unavailable(message) : .stale(message)
                }
            }
        }
    }
}
