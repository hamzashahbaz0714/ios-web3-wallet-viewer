//
//  EthereumBalanceFormatter.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 14/02/2026.
//

import Foundation

enum EthereumBalanceFormatter {
    /// Converts hex wei string (e.g. "0x1bc16d674ec80000") into ETH string (e.g. "2.000000")
    static func ethString(fromHexWei hex: String, fractionDigits: Int = 6) -> String? {
        let clean = hex.lowercased().replacingOccurrences(of: "0x", with: "")
        guard !clean.isEmpty else { return nil }

        let digits = Array(clean)
        let hexMap: [Character: Int] = [
            "0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9,
            "a": 10, "b": 11, "c": 12, "d": 13, "e": 14, "f": 15
        ]

        var wei = Decimal(0)
        for ch in digits {
            guard let v = hexMap[ch] else { return nil }
            wei = wei * 16 + Decimal(v)
        }

        let ethDivisor = Decimal(string: "1000000000000000000")! // 1e18
        let eth = wei / ethDivisor

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = fractionDigits
        formatter.usesGroupingSeparator = false

        return formatter.string(from: eth as NSDecimalNumber)
    }
}
