//
//  Chain.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 13/02/2026.
//

import Foundation

enum Chain: String, CaseIterable, Identifiable, Codable {
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
            return URL(string: "https://ethereum.publicnode.com")!
        case .sepolia:
            return URL(string: "https://ethereum-sepolia.publicnode.com")!
        }
    }

    var covalentChainId: String {
        switch self {
        case .ethereumMainnet: return "1"
        case .sepolia: return "11155111"
        }
    }
}

