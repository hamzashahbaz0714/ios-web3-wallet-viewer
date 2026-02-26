//
//  WalletInputParser.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 15/02/2026.
//

import Foundation

enum WalletInputParser {
    static func extractAddress(from input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // raw address
        if trimmed.lowercased().hasPrefix("0x"), trimmed.count >= 42 {
            return String(trimmed.prefix(42))
        }

        // if pasted URL or text with query params, extract 0x... pattern
        if let range = trimmed.range(of: "0x[a-fA-F0-9]{40}", options: .regularExpression) {
            return String(trimmed[range])
        }

        return trimmed
    }
}
