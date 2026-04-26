//
//  LlamaServerDefaults.swift
//  LlamaLocalServer
//
//  Created by Максим Ламанский on 26.04.26.
//

import Foundation

enum LlamaServerDefaults {
    private static let projectRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    static let serverBinaryPath = "/opt/homebrew/bin/llama-server"
    static let modelPath = projectRoot
        .appendingPathComponent("Models/qwen2.5-0.5b-instruct-q4_k_m.gguf")
        .path
    static let host = "127.0.0.1"
    static let port = 8080
    static let apiKey = "change-me"
    static let modelAlias = "local-private"
    static let contextSize = 16_384
    static let parallelSlots = 2
    static let maxGeneratedTokens = 2_048
    static let threads = -1
    static let restartDelaySeconds = 3
}
