//
//  WalletViewerService.swift.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 13/02/2026.
//

import Foundation

protocol WalletViewerServiceProtocol {
    func fetchWalletSummary(address: String, chain: Chain) async throws -> WalletSummary
}

enum WalletViewerServiceError: LocalizedError {
    case invalidAddress
    
    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "Please enter a valid wallet address."
        }
    }
}

final class MockWalletViewerService: WalletViewerServiceProtocol {
    func fetchWalletSummary(address: String, chain: Chain) async throws -> WalletSummary {
        guard EthereumAddressValidator.isValid(address) else {
            throw WalletViewerServiceError.invalidAddress
        }
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 700_000_000)
        
        return WalletSummary(
            address: address,
            chain: chain,
            nativeBalance: "1.2487 \(chain.symbol)",
            tokens: [
                TokenBalance(symbol: "USDC", amount: "245.32"),
                TokenBalance(symbol: "UNI", amount: "18.00"),
                TokenBalance(symbol: "LINK", amount: "7.45")
            ]
        )
    }
}
