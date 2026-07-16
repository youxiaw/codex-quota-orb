import Foundation

@discardableResult
func require(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
    return true
}

final class MemoryRPCTransport: CodexRPCTransport {
    private var lines: [String]
    private(set) var writes: [String] = []

    init(lines: [String]) {
        self.lines = lines
    }

    func writeLine(_ line: String) throws {
        writes.append(line)
    }

    func readLine() throws -> String? {
        guard !lines.isEmpty else { return nil }
        return lines.removeFirst()
    }

    func close() {}
}

func methodNames(from writes: [String]) -> [String] {
    writes.compactMap { line in
        guard let data = line.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        return object["method"] as? String
    }
}

let rateResponse = """
{"id":2,"result":{"rateLimits":{"primary":{"usedPercent":20,"windowDurationMins":300,"resetsAt":1783934400},"secondary":{"usedPercent":45,"windowDurationMins":10080,"resetsAt":1784366400}}}}
"""
let transport = MemoryRPCTransport(lines: [
    #"{"id":1,"result":{}}"#,
    rateResponse
])
let client = CodexRPCClient(transport: transport)
let snapshot = try client.fetchSnapshot(now: Date(timeIntervalSince1970: 300))
let methods = methodNames(from: transport.writes)

require(methods == ["initialize", "initialized", "account/rateLimits/read"], "RPC method sequence")
require(snapshot.fiveHour?.remainingPercent == 80, "RPC five-hour remaining")
require(snapshot.weekly?.remainingPercent == 55, "RPC weekly remaining")
print("RPCTests passed")
