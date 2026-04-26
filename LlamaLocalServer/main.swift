//
//  main.swift
//  LlamaLocalServer
//
//  Created by Максим Ламанский on 26.04.26.
//

import Foundation

protocol LlamaServerDaemonProtocol {
    func run() throws
}

struct LlamaServerConfiguration {
    let serverBinaryPath: String
    let modelPath: String
    let host: String
    let port: Int
    let apiKey: String
    let modelAlias: String
    let contextSize: Int
    let parallelSlots: Int
    let maxGeneratedTokens: Int
    let threads: Int
    let restartDelaySeconds: UInt32

    static func load(environment: [String: String] = ProcessInfo.processInfo.environment) throws -> LlamaServerConfiguration {
        return LlamaServerConfiguration(
            serverBinaryPath: stringValue("LLAMA_SERVER_BIN", in: environment, defaultValue: LlamaServerDefaults.serverBinaryPath),
            modelPath: stringValue("LLAMA_MODEL_PATH", in: environment, defaultValue: LlamaServerDefaults.modelPath),
            host: stringValue("LLAMA_HOST", in: environment, defaultValue: LlamaServerDefaults.host),
            port: intValue("LLAMA_PORT", in: environment, defaultValue: LlamaServerDefaults.port),
            apiKey: stringValue("LLAMA_API_KEY", in: environment, defaultValue: LlamaServerDefaults.apiKey),
            modelAlias: stringValue("LLAMA_MODEL_ALIAS", in: environment, defaultValue: LlamaServerDefaults.modelAlias),
            contextSize: intValue("LLAMA_CTX_SIZE", in: environment, defaultValue: LlamaServerDefaults.contextSize),
            parallelSlots: intValue("LLAMA_PARALLEL", in: environment, defaultValue: LlamaServerDefaults.parallelSlots),
            maxGeneratedTokens: intValue("LLAMA_N_PREDICT", in: environment, defaultValue: LlamaServerDefaults.maxGeneratedTokens),
            threads: intValue("LLAMA_THREADS", in: environment, defaultValue: LlamaServerDefaults.threads),
            restartDelaySeconds: UInt32(intValue("LLAMA_RESTART_DELAY_SECONDS", in: environment, defaultValue: LlamaServerDefaults.restartDelaySeconds))
        )
    }

    var arguments: [String] {
        [
            "--model", modelPath,
            "--host", host,
            "--port", String(port),
            "--api-key", apiKey,
            "--alias", modelAlias,
            "--ctx-size", String(contextSize),
            "--parallel", String(parallelSlots),
            "--n-predict", String(maxGeneratedTokens),
            "--threads", String(threads)
        ]
    }

    private static func stringValue(_ key: String, in environment: [String: String], defaultValue: String) -> String {
        guard let value = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return defaultValue
        }
        return value
    }

    private static func intValue(_ key: String, in environment: [String: String], defaultValue: Int) -> Int {
        guard let rawValue = environment[key], let value = Int(rawValue) else {
            return defaultValue
        }
        return value
    }
}

final class LlamaServerDaemon: LlamaServerDaemonProtocol {
    private let configuration: LlamaServerConfiguration
    private var isStopping = false
    private var childProcess: Process?

    init(configuration: LlamaServerConfiguration) {
        self.configuration = configuration
        installSignalHandlers()
    }

    func run() throws {
        logConfiguration()

        while !isStopping {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: configuration.serverBinaryPath)
            process.arguments = configuration.arguments
            childProcess = process

            do {
                try process.run()
            } catch {
                throw LlamaServerDaemonError.launchFailed(error.localizedDescription)
            }

            process.waitUntilExit()

            guard !isStopping else { break }

            let status = process.terminationStatus
            log("llama-server exited with status \(status). Restarting in \(configuration.restartDelaySeconds)s.")
            sleep(configuration.restartDelaySeconds)
        }
    }

    private func installSignalHandlers() {
        signal(SIGINT) { _ in
            LlamaServerDaemonSignalBridge.shared.stop()
        }
        signal(SIGTERM) { _ in
            LlamaServerDaemonSignalBridge.shared.stop()
        }
        LlamaServerDaemonSignalBridge.shared.onStop = { [weak self] in
            self?.isStopping = true
            self?.childProcess?.terminate()
        }
    }

    private func logConfiguration() {
        log("Starting llama-server daemon.")
        log("Binary: \(configuration.serverBinaryPath)")
        log("Model: \(configuration.modelPath)")
        log("Endpoint: http://\(configuration.host):\(configuration.port)/v1/chat/completions")
        log("Alias: \(configuration.modelAlias)")
        log("Context: \(configuration.contextSize), parallel slots: \(configuration.parallelSlots), max output: \(configuration.maxGeneratedTokens)")
    }

    private func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        FileHandle.standardError.write(Data("[\(timestamp)] \(message)\n".utf8))
    }
}

final class LlamaServerDaemonSignalBridge {
    static let shared = LlamaServerDaemonSignalBridge()
    var onStop: (() -> Void)?

    private init() {}

    func stop() {
        onStop?()
    }
}

enum LlamaServerDaemonError: LocalizedError {
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .launchFailed(let message):
            return "Failed to launch llama-server: \(message)"
        }
    }
}

do {
    let configuration = try LlamaServerConfiguration.load()
    let daemon = LlamaServerDaemon(configuration: configuration)
    try daemon.run()
} catch {
    FileHandle.standardError.write(Data("LlamaLocalServer failed: \(error.localizedDescription)\n".utf8))
    exit(1)
}
