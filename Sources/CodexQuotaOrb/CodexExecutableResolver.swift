import Foundation

enum CodexExecutableResolver {
    static func resolve(environment: [String: String] = ProcessInfo.processInfo.environment) -> String? {
        let fileManager = FileManager.default
        let candidates = fixedCandidates(environment: environment) + pathCandidates(environment: environment)
        return candidates.first { fileManager.isExecutableFile(atPath: $0) }
    }

    private static func fixedCandidates(environment: [String: String]) -> [String] {
        var candidates = [
            "/Applications/ChatGPT.app/Contents/Resources/codex",
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex"
        ]

        if let home = environment["HOME"], !home.isEmpty {
            candidates.append("\(home)/.local/bin/codex")
            candidates.append("\(home)/.nvm/versions/node/v20.20.2/bin/codex")
            candidates.append("\(home)/.nvm/versions/node/v24.12.0/bin/codex")
        }

        return candidates
    }

    private static func pathCandidates(environment: [String: String]) -> [String] {
        guard let path = environment["PATH"] else {
            return []
        }
        return path
            .split(separator: ":")
            .map { String($0) }
            .filter { !$0.isEmpty }
            .map { "\($0)/codex" }
    }
}
