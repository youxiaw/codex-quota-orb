import Foundation

final class ProcessCodexRPCTransport: CodexRPCTransport {
    private let process: Process
    private let input: FileHandle
    private let output: FileHandle

    init(executablePath: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = ["app-server", "--stdio"]

        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()

        self.process = process
        self.input = stdin.fileHandleForWriting
        self.output = stdout.fileHandleForReading
    }

    func writeLine(_ line: String) throws {
        guard let data = "\(line)\n".data(using: .utf8) else {
            return
        }
        try input.write(contentsOf: data)
    }

    func readLine() throws -> String? {
        let semaphore = DispatchSemaphore(value: 0)
        final class Box: @unchecked Sendable {
            var line: String?
        }
        let box = Box()

        DispatchQueue.global(qos: .utility).async { [output] in
            box.line = Self.blockingReadLine(from: output)
            semaphore.signal()
        }

        guard semaphore.wait(timeout: .now() + 8) == .success else {
            return nil
        }
        return box.line
    }

    private static func blockingReadLine(from output: FileHandle) -> String? {
        var data = Data()
        while true {
            let byte = output.readData(ofLength: 1)
            if byte.isEmpty {
                return data.isEmpty ? nil : String(data: data, encoding: .utf8)
            }
            if byte == Data([0x0a]) {
                return String(data: data, encoding: .utf8)
            }
            data.append(byte)
        }
    }

    func close() {
        try? input.close()
        if process.isRunning {
            process.terminate()
        }
    }

    deinit {
        close()
    }
}
