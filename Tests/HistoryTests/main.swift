import Foundation

@discardableResult
func require(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
    return true
}

let databaseURL = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("codex-quota-history-\(UUID().uuidString).sqlite")
let store = try QuotaHistoryStore(databaseURL: databaseURL)

let first = QuotaSnapshot(
    fiveHour: QuotaWindow(
        remainingPercent: 80,
        usedPercent: 20,
        windowDurationMinutes: 300,
        resetAt: Date(timeIntervalSince1970: 1_783_934_400)
    ),
    weekly: QuotaWindow(
        remainingPercent: 55,
        usedPercent: 45,
        windowDurationMinutes: 10_080,
        resetAt: Date(timeIntervalSince1970: 1_784_366_400)
    ),
    updatedAt: Date(timeIntervalSince1970: 300)
)
let second = QuotaSnapshot(
    fiveHour: nil,
    weekly: QuotaWindow(
        remainingPercent: 51,
        usedPercent: 49,
        windowDurationMinutes: 10_080,
        resetAt: Date(timeIntervalSince1970: 1_784_269_695)
    ),
    updatedAt: Date(timeIntervalSince1970: 600)
)

try store.save(first)
try store.save(second)
let samples = try store.recentSamples(limit: 10)

require(samples.count == 2, "history sample count")
require(samples[0].updatedAt == second.updatedAt, "newest sample first")
require(samples[0].weekly?.remainingPercent == 51, "newest weekly remaining")
require(samples[0].fiveHour == nil, "nil five-hour persists")
require(samples[1].fiveHour?.remainingPercent == 80, "older five-hour remaining")

try? FileManager.default.removeItem(at: databaseURL)
print("HistoryTests passed")
