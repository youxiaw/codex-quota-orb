import Foundation

struct QuotaWindow: Equatable {
    let remainingPercent: Double
    let usedPercent: Double
    let windowDurationMinutes: Int?
    let resetAt: Date?
}

struct QuotaSnapshot: Equatable {
    let fiveHour: QuotaWindow?
    let weekly: QuotaWindow?
    let updatedAt: Date

    var mostConstrainedRemainingPercent: Double? {
        [fiveHour?.remainingPercent, weekly?.remainingPercent]
            .compactMap { $0 }
            .min()
    }
}

enum QuotaParseError: Error, Equatable, CustomStringConvertible {
    case invalidJSON
    case missingRateLimits

    var description: String {
        switch self {
        case .invalidJSON:
            return "Invalid JSON response."
        case .missingRateLimits:
            return "No valid Codex rate-limit windows were found."
        }
    }
}
