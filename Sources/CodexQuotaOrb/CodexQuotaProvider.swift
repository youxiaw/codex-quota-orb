import Foundation

enum CodexQuotaProviderError: Error, CustomStringConvertible {
    case executableNotFound

    var description: String {
        switch self {
        case .executableNotFound:
            return "Codex executable was not found. Install or sign in to Codex, then try again."
        }
    }
}

struct CodexQuotaProvider {
    var now: () -> Date = Date.init

    func fetch() throws -> QuotaSnapshot {
        guard let executable = CodexExecutableResolver.resolve() else {
            throw CodexQuotaProviderError.executableNotFound
        }
        let transport = try ProcessCodexRPCTransport(executablePath: executable)
        defer { transport.close() }
        let client = CodexRPCClient(transport: transport)
        return try client.fetchSnapshot(now: now())
    }
}
