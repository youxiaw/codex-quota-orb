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
let filteredSamples = try store.samples(since: Date(timeIntervalSince1970: 450), limit: 10)

require(samples.count == 2, "history sample count")
require(samples[0].updatedAt == second.updatedAt, "newest sample first")
require(samples[0].weekly?.remainingPercent == 51, "newest weekly remaining")
require(samples[0].fiveHour == nil, "nil five-hour persists")
require(samples[1].fiveHour?.remainingPercent == 80, "older five-hour remaining")
require(filteredSamples.count == 1, "filtered history sample count")
require(filteredSamples[0].updatedAt == second.updatedAt, "filtered history includes only samples inside range")

let retentionDatabaseURL = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("codex-quota-retention-\(UUID().uuidString).sqlite")
let retentionStore = try QuotaHistoryStore(databaseURL: retentionDatabaseURL)
let oldSnapshot = QuotaSnapshot(
    fiveHour: nil,
    weekly: QuotaWindow(
        remainingPercent: 10,
        usedPercent: 90,
        windowDurationMinutes: 10_080,
        resetAt: nil
    ),
    updatedAt: Date(timeIntervalSince1970: 1_000)
)
let retainedSnapshot = QuotaSnapshot(
    fiveHour: nil,
    weekly: QuotaWindow(
        remainingPercent: 88,
        usedPercent: 12,
        windowDurationMinutes: 10_080,
        resetAt: nil
    ),
    updatedAt: Date(timeIntervalSince1970: 1_000 + 31 * 24 * 60 * 60)
)
let nextDayOldSnapshot = QuotaSnapshot(
    fiveHour: nil,
    weekly: QuotaWindow(
        remainingPercent: 20,
        usedPercent: 80,
        windowDurationMinutes: 10_080,
        resetAt: nil
    ),
    updatedAt: Date(timeIntervalSince1970: 2_000)
)

try retentionStore.save(oldSnapshot)
try retentionStore.save(retainedSnapshot)
let retainedSamples = try retentionStore.recentSamples(limit: 10)
require(retainedSamples.count == 1, "retention cleanup removes samples older than 30 days")
require(retainedSamples[0].updatedAt == retainedSnapshot.updatedAt, "retention cleanup keeps recent sample")

try retentionStore.save(nextDayOldSnapshot)
let skippedCleanupSamples = try retentionStore.recentSamples(limit: 10)
require(skippedCleanupSamples.count == 2, "retention cleanup is skipped when already run recently")

try? FileManager.default.removeItem(at: databaseURL)
try? FileManager.default.removeItem(at: retentionDatabaseURL)
print("HistoryTests passed")
