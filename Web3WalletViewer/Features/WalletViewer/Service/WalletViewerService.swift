//
//  WalletViewerService.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 14/02/2026.
//
import Foundation

protocol WalletViewerServiceProtocol {
    func fetchWalletSummary(address: String, chain: Chain) async throws -> WalletSummary
}

enum WalletViewerServiceError: LocalizedError {
    case invalidAddress
    case invalidBalanceFormat

    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "Please enter a valid wallet address."
        case .invalidBalanceFormat:
            return "Could not parse wallet balance."
        }
    }
}

final class WalletViewerService: WalletViewerServiceProtocol {
    private let rpcClient: RPCClientProtocol

    init(rpcClient: RPCClientProtocol = RPCClient()) {
        self.rpcClient = rpcClient
    }

    func fetchWalletSummary(address: String, chain: Chain) async throws -> WalletSummary {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard EthereumAddressValidator.isValid(trimmed) else {
            throw WalletViewerServiceError.invalidAddress
        }

        // eth_getBalance params: [address, "latest"]
        let params = [trimmed, "latest"]
        let hexWei: String = try await rpcClient.call(
            url: chain.rpcURL,
            method: "eth_getBalance",
            params: params
        )

        guard let eth = EthereumBalanceFormatter.ethString(fromHexWei: hexWei) else {
            throw WalletViewerServiceError.invalidBalanceFormat
        }

        // Keep token list mock for now (Day 3+ can replace with real token API/indexer)
        let tokens = [
            TokenBalance(symbol: "USDC", amount: "--"),
            TokenBalance(symbol: "UNI", amount: "--"),
            TokenBalance(symbol: "LINK", amount: "--")
        ]

        return WalletSummary(
            address: trimmed,
            chain: chain,
            nativeBalance: "\(eth) \(chain.symbol)",
            tokens: tokens
        )
    }
}
