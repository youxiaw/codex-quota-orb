import Foundation

@discardableResult
func require(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
    return true
}

func requireThrows<T: Error & Equatable>(_ expected: T, _ body: () throws -> Void, _ message: String) {
    do {
        try body()
        fputs("FAIL: \(message) did not throw\n", stderr)
        exit(1)
    } catch let error as T {
        require(error == expected, "\(message) threw \(error), expected \(expected)")
    } catch {
        fputs("FAIL: \(message) threw unexpected error \(error)\n", stderr)
        exit(1)
    }
}

func testParsesLegacyPrimaryAndSecondaryRateLimits() throws {
    let json = """
    {
      "result": {
        "rateLimits": {
          "primary": {
            "usedPercent": 14,
            "windowDurationMins": 300,
            "resetsAt": 1783934400
          },
          "secondary": {
            "usedPercent": 38,
            "windowDurationMins": 10080,
            "resetsAt": 1784366400
          }
        }
      }
    }
    """

    let snapshot = try CodexRateLimitParser.parse(Data(json.utf8), now: Date(timeIntervalSince1970: 100))

    require(snapshot.fiveHour?.remainingPercent == 86, "five-hour remaining percent")
    require(snapshot.fiveHour?.windowDurationMinutes == 300, "five-hour duration")
    require(snapshot.weekly?.remainingPercent == 62, "weekly remaining percent")
    require(snapshot.weekly?.windowDurationMinutes == 10080, "weekly duration")
    require(snapshot.updatedAt == Date(timeIntervalSince1970: 100), "updated timestamp")
}

func testParsesCodexBucketRateLimits() throws {
    let json = """
    {
      "result": {
        "rateLimitsByLimitId": {
          "codex": {
            "primary": {
              "usedPercent": 49,
              "windowDurationMins": 10080,
              "resetsAt": 1784269695
            }
          }
        }
      }
    }
    """

    let snapshot = try CodexRateLimitParser.parse(Data(json.utf8), now: Date(timeIntervalSince1970: 200))

    require(snapshot.fiveHour == nil, "codex bucket has no five-hour sample")
    require(snapshot.weekly?.remainingPercent == 51, "codex bucket weekly remaining")
    require(snapshot.weekly?.resetAt == Date(timeIntervalSince1970: 1784269695), "codex bucket reset")
}

func testRejectsInvalidUsedPercent() {
    let json = """
    {
      "result": {
        "rateLimits": {
          "primary": {
            "usedPercent": 140,
            "windowDurationMins": 300
          }
        }
      }
    }
    """

    requireThrows(QuotaParseError.missingRateLimits, {
        _ = try CodexRateLimitParser.parse(Data(json.utf8), now: Date())
    }, "invalid used percent")
}

do {
    try testParsesLegacyPrimaryAndSecondaryRateLimits()
    try testParsesCodexBucketRateLimits()
    testRejectsInvalidUsedPercent()
    print("ParserTests passed")
} catch {
    fputs("FAIL: unexpected top-level error \(error)\n", stderr)
    exit(1)
}
