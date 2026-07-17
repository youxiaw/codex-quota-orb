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
    @Published private(set) var trendRange: QuotaTrendRange = .oneHour

    private let provider: CodexQuotaProvider
    private let store: QuotaHistoryStore

    init(provider: CodexQuotaProvider = CodexQuotaProvider(), store: QuotaHistoryStore) {
        self.provider = provider
        self.store = store
        self.history = Self.loadHistory(from: store, range: trendRange)
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
        let range = trendRange
        Task.detached { [provider, store] in
            do {
                let snapshot = try provider.fetch()
                try store.save(snapshot)
                let history = Self.loadHistory(from: store, range: range)
                await MainActor.run {
                    self.snapshot = snapshot
                    self.history = history
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

    func setTrendRange(_ range: QuotaTrendRange) {
        guard range != trendRange else {
            return
        }
        trendRange = range
        history = Self.loadHistory(from: store, range: range)
        snapshot = history.last ?? snapshot
    }

    nonisolated private static func loadHistory(from store: QuotaHistoryStore, range: QuotaTrendRange, now: Date = Date()) -> [QuotaSnapshot] {
        let startDate = now.addingTimeInterval(-range.interval)
        let samples = (try? store.samples(since: startDate, limit: range.maxSamples)) ?? []
        return Array(samples.reversed())
    }
}
