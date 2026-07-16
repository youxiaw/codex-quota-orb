import Foundation
import SQLite3

final class QuotaHistoryStore {
    private let databaseURL: URL

    init(databaseURL: URL = QuotaHistoryStore.defaultDatabaseURL()) throws {
        self.databaseURL = databaseURL
        try FileManager.default.createDirectory(
            at: databaseURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try withDatabase { database in
            try execute(
                database,
                """
                CREATE TABLE IF NOT EXISTS quota_samples (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    updated_at REAL NOT NULL,
                    five_hour_remaining REAL,
                    five_hour_used REAL,
                    five_hour_reset_at REAL,
                    weekly_remaining REAL,
                    weekly_used REAL,
                    weekly_reset_at REAL
                );
                """
            )
        }
    }

    func save(_ snapshot: QuotaSnapshot) throws {
        try withDatabase { database in
            let sql = """
            INSERT INTO quota_samples (
                updated_at,
                five_hour_remaining,
                five_hour_used,
                five_hour_reset_at,
                weekly_remaining,
                weekly_used,
                weekly_reset_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?);
            """
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
                throw error(database)
            }
            defer { sqlite3_finalize(statement) }

            bind(statement, 1, snapshot.updatedAt.timeIntervalSince1970)
            bind(statement, 2, snapshot.fiveHour?.remainingPercent)
            bind(statement, 3, snapshot.fiveHour?.usedPercent)
            bind(statement, 4, snapshot.fiveHour?.resetAt?.timeIntervalSince1970)
            bind(statement, 5, snapshot.weekly?.remainingPercent)
            bind(statement, 6, snapshot.weekly?.usedPercent)
            bind(statement, 7, snapshot.weekly?.resetAt?.timeIntervalSince1970)

            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw error(database)
            }
        }
    }

    func recentSamples(limit: Int) throws -> [QuotaSnapshot] {
        try withDatabase { database in
            let sql = """
            SELECT updated_at,
                   five_hour_remaining,
                   five_hour_used,
                   five_hour_reset_at,
                   weekly_remaining,
                   weekly_used,
                   weekly_reset_at
            FROM quota_samples
            ORDER BY updated_at DESC
            LIMIT ?;
            """
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
                throw error(database)
            }
            defer { sqlite3_finalize(statement) }
            sqlite3_bind_int(statement, 1, Int32(max(1, limit)))

            var snapshots: [QuotaSnapshot] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                let updatedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 0))
                let fiveHour = readWindow(statement, remainingIndex: 1, usedIndex: 2, resetIndex: 3, duration: 300)
                let weekly = readWindow(statement, remainingIndex: 4, usedIndex: 5, resetIndex: 6, duration: 10_080)
                snapshots.append(QuotaSnapshot(fiveHour: fiveHour, weekly: weekly, updatedAt: updatedAt))
            }
            return snapshots
        }
    }

    static func defaultDatabaseURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return appSupport
            .appendingPathComponent("CodexQuotaOrb", isDirectory: true)
            .appendingPathComponent("history.sqlite")
    }

    private func withDatabase<T>(_ body: (OpaquePointer) throws -> T) throws -> T {
        var database: OpaquePointer?
        guard sqlite3_open_v2(databaseURL.path, &database, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK,
              let database
        else {
            throw NSError(domain: "QuotaHistoryStore", code: 1)
        }
        defer { sqlite3_close(database) }
        return try body(database)
    }

    private func execute(_ database: OpaquePointer, _ sql: String) throws {
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw error(database)
        }
    }

    private func error(_ database: OpaquePointer) -> NSError {
        let message = sqlite3_errmsg(database).map { String(cString: $0) } ?? "SQLite error"
        return NSError(domain: "QuotaHistoryStore", code: Int(sqlite3_errcode(database)), userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    }

    private func bind(_ statement: OpaquePointer?, _ index: Int32, _ value: Double?) {
        if let value {
            sqlite3_bind_double(statement, index, value)
        } else {
            sqlite3_bind_null(statement, index)
        }
    }

    private func readWindow(
        _ statement: OpaquePointer?,
        remainingIndex: Int32,
        usedIndex: Int32,
        resetIndex: Int32,
        duration: Int
    ) -> QuotaWindow? {
        guard sqlite3_column_type(statement, remainingIndex) != SQLITE_NULL,
              sqlite3_column_type(statement, usedIndex) != SQLITE_NULL
        else {
            return nil
        }

        let resetAt: Date?
        if sqlite3_column_type(statement, resetIndex) == SQLITE_NULL {
            resetAt = nil
        } else {
            resetAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, resetIndex))
        }

        return QuotaWindow(
            remainingPercent: sqlite3_column_double(statement, remainingIndex),
            usedPercent: sqlite3_column_double(statement, usedIndex),
            windowDurationMinutes: duration,
            resetAt: resetAt
        )
    }
}
