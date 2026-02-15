//
//  WalletTransaction.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 15/02/2026.
//

import Foundation

struct WalletTransaction: Identifiable, Equatable {
    let id: String            // tx hash
    let hash: String
    let from: String
    let to: String
    let value: String         // formatted (ETH)
    let timestamp: Date?
    let isIncoming: Bool
    let chain: Chain
}
