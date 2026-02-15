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
    private let tokenService: TokenBalanceServiceProtocol

    init(
        rpcClient: RPCClientProtocol = RPCClient(),
        tokenService: TokenBalanceServiceProtocol = TokenBalanceService()
    ) {
        self.rpcClient = rpcClient
        self.tokenService = tokenService
    }

    func fetchWalletSummary(address: String, chain: Chain) async throws -> WalletSummary {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard EthereumAddressValidator.isValid(trimmed) else {
            throw WalletViewerServiceError.invalidAddress
        }

        // 1) Native balance (required)
        let params = [trimmed, "latest"]
        let hexWei: String = try await rpcClient.call(
            url: chain.rpcURL,
            method: "eth_getBalance",
            params: params
        )

        guard let eth = EthereumBalanceFormatter.ethString(fromHexWei: hexWei) else {
            throw WalletViewerServiceError.invalidBalanceFormat
        }

        // 2) Token balances (best-effort, non-blocking failure)
        let tokens: [TokenHolding]
        do {
            tokens = try await tokenService.fetchTokenBalances(address: trimmed, chain: chain)
        } catch {
            print("Token fetch failed (continuing with native only): \(error.localizedDescription)")
            tokens = []
        }

        return WalletSummary(
            address: trimmed,
            chain: chain,
            nativeBalance: "\(eth) \(chain.symbol)",
            tokens: tokens
        )
    }
}
