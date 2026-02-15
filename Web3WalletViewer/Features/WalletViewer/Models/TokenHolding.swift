//
//  TokenHolding.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 15/02/2026.
//

import Foundation

struct TokenHolding: Identifiable, Equatable {
    let id: String               // contract address is good unique id
    let symbol: String
    let amount: String           // formatted human-readable
    let contractAddress: String
    let decimals: Int
}
