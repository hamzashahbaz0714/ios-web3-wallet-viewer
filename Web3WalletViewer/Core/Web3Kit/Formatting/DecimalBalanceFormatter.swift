//
//  DecimalBalanceFormatter.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 15/02/2026.
//

import Foundation

enum DecimalBalanceFormatter {
    /// rawBalance is integer string in token smallest units; decimals is token decimals
    static func formatTokenBalance(rawBalance: String, decimals: Int, maxFractionDigits: Int = 6) -> String? {
        guard let raw = Decimal(string: rawBalance), decimals >= 0 else { return nil }

        let divisor = pow10(decimals)
        guard divisor != 0 else { return nil }

        let human = raw / divisor

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maxFractionDigits

        return formatter.string(from: human as NSDecimalNumber)
    }

    private static func pow10(_ exp: Int) -> Decimal {
        guard exp > 0 else { return 1 }
        var result = Decimal(1)
        for _ in 0..<exp {
            result *= 10
        }
        return result
    }
}
