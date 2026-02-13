//
//  WalletSummary.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 13/02/2026.
//

import Foundation

struct WalletSummary {
    let address: String
    let chain: Chain
    let nativeBalance: String
    let tokens: [TokenBalance]
}

struct TokenBalance: Identifiable {
    let id = UUID()
    let symbol: String
    let amount: String
}
