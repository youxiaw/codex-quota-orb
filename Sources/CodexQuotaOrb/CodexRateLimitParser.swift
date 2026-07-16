import Foundation

enum CodexRateLimitParser {
    static func parse(_ data: Data, now: Date) throws -> QuotaSnapshot {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw QuotaParseError.invalidJSON
        }

        let result = dictionary(root["result"]) ?? root
        let windows = collectWindows(from: result)
        let fiveHour = windows.first { $0.windowDurationMinutes == 300 }
        let weekly = windows.first { $0.windowDurationMinutes == 10_080 }

        guard fiveHour != nil || weekly != nil else {
            throw QuotaParseError.missingRateLimits
        }

        return QuotaSnapshot(fiveHour: fiveHour, weekly: weekly, updatedAt: now)
    }

    private static func collectWindows(from result: [String: Any]) -> [QuotaWindow] {
        var windows: [QuotaWindow] = []

        if let rateLimits = dictionary(result["rateLimits"]) {
            appendWindow(rateLimits["primary"], to: &windows)
            appendWindow(rateLimits["secondary"], to: &windows)
        }

        if let byLimitId = dictionary(result["rateLimitsByLimitId"]),
           let codex = dictionary(byLimitId["codex"]) {
            appendWindow(codex["primary"], to: &windows)
            appendWindow(codex["secondary"], to: &windows)
        }

        return windows
    }

    private static func appendWindow(_ value: Any?, to windows: inout [QuotaWindow]) {
        guard let object = dictionary(value),
              let usedPercent = number(object["usedPercent"] ?? object["used_percent"]),
              usedPercent.isFinite,
              (0...100).contains(usedPercent)
        else {
            return
        }

        let duration = integer(object["windowDurationMins"] ?? object["window_duration_mins"])
        let resetAt = number(object["resetsAt"] ?? object["resets_at"])
            .map { Date(timeIntervalSince1970: $0) }
        windows.append(
            QuotaWindow(
                remainingPercent: 100 - usedPercent,
                usedPercent: usedPercent,
                windowDurationMinutes: duration,
                resetAt: resetAt
            )
        )
    }

    private static func dictionary(_ value: Any?) -> [String: Any]? {
        value as? [String: Any]
    }

    private static func number(_ value: Any?) -> Double? {
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let string = value as? String {
            return Double(string)
        }
        return nil
    }

    private static func integer(_ value: Any?) -> Int? {
        if let number = value as? NSNumber {
            return number.intValue
        }
        if let string = value as? String {
            return Int(string)
        }
        return nil
    }
}
