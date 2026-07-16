import Foundation

protocol CodexRPCTransport: AnyObject {
    func writeLine(_ line: String) throws
    func readLine() throws -> String?
    func close()
}

enum CodexRPCError: Error, CustomStringConvertible {
    case closed
    case malformedResponse
    case rpcError(String)

    var description: String {
        switch self {
        case .closed:
            return "Codex app-server closed before returning a response."
        case .malformedResponse:
            return "Codex app-server returned malformed JSON."
        case .rpcError(let message):
            return message
        }
    }
}

final class CodexRPCClient {
    private let transport: CodexRPCTransport
    private var nextID = 0

    init(transport: CodexRPCTransport) {
        self.transport = transport
    }

    func fetchSnapshot(now: Date = Date()) throws -> QuotaSnapshot {
        _ = try sendRequest(method: "initialize", params: [
            "clientInfo": [
                "name": "codex-quota-orb",
                "version": "0.1.0"
            ]
        ])
        try sendNotification(method: "initialized")
        let response = try sendRequest(method: "account/rateLimits/read", params: [:])
        let responseData = try JSONSerialization.data(withJSONObject: ["result": response])
        return try CodexRateLimitParser.parse(responseData, now: now)
    }

    private func sendNotification(method: String) throws {
        let payload: [String: Any] = [
            "method": method,
            "params": [:]
        ]
        try transport.writeLine(try encode(payload))
    }

    private func sendRequest(method: String, params: [String: Any]) throws -> [String: Any] {
        nextID += 1
        let id = nextID
        let payload: [String: Any] = [
            "id": id,
            "method": method,
            "params": params
        ]
        try transport.writeLine(try encode(payload))

        while true {
            guard let line = try transport.readLine() else {
                throw CodexRPCError.closed
            }
            guard let data = line.data(using: .utf8),
                  let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                throw CodexRPCError.malformedResponse
            }
            guard let responseID = object["id"] as? Int, responseID == id else {
                continue
            }
            if let error = object["error"] as? [String: Any] {
                throw CodexRPCError.rpcError(error["message"] as? String ?? "Codex app-server returned an RPC error.")
            }
            guard let result = object["result"] as? [String: Any] else {
                throw CodexRPCError.malformedResponse
            }
            return result
        }
    }

    private func encode(_ payload: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: payload)
        return String(decoding: data, as: UTF8.self)
    }
}
