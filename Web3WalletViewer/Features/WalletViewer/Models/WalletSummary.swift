//
//  WalletSummary.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 13/02/2026.
//

import Foundation
import Foundation

struct WalletSummary: Equatable {
    let address: String
    let chain: Chain
    let nativeBalance: String
    let tokens: [TokenHolding]
}


struct TokenBalance: Identifiable {
    let id = UUID()
    let symbol: String
    let amount: String
}
