import Foundation

enum QuotaTrendRange: String, CaseIterable, Identifiable {
    case oneHour
    case sixHours
    case oneDay
    case oneWeek

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .oneHour:
            return "1h"
        case .sixHours:
            return "6h"
        case .oneDay:
            return "24h"
        case .oneWeek:
            return "7d"
        }
    }

    var interval: TimeInterval {
        switch self {
        case .oneHour:
            return 60 * 60
        case .sixHours:
            return 6 * 60 * 60
        case .oneDay:
            return 24 * 60 * 60
        case .oneWeek:
            return 7 * 24 * 60 * 60
        }
    }

    var maxSamples: Int {
        switch self {
        case .oneHour:
            return 90
        case .sixHours:
            return 360
        case .oneDay:
            return 720
        case .oneWeek:
            return 1_000
        }
    }
}
