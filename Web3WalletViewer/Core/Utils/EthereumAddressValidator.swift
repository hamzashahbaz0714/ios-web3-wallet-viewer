//
//  EthereumAddressValidator.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 13/02/2026.
//

import Foundation

enum EthereumAddressValidator {
    static func isValid(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("0x"), trimmed.count == 42 else { return false }
        let hexPart = trimmed.dropFirst(2)
        let hexSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return hexPart.unicodeScalars.allSatisfy { hexSet.contains($0) }
    }
}
