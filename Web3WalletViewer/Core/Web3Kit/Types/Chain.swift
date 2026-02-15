//
//  Chain.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 13/02/2026.
//

import Foundation

enum Chain: String, CaseIterable, Identifiable {
    case ethereumMainnet = "Ethereum Mainnet"
    case sepolia = "Sepolia Testnet"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .ethereumMainnet, .sepolia: return "ETH"
        }
    }

    var rpcURL: URL {
        switch self {
        case .ethereumMainnet:
            // Public + stable for demo
            return URL(string: "https://ethereum.publicnode.com")!
        case .sepolia:
            // Public sepolia endpoint
            return URL(string: "https://ethereum-sepolia.publicnode.com")!
        }
    }
}
