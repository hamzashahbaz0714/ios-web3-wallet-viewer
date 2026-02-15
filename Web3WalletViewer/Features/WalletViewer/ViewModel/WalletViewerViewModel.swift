//
//  WalletViewerViewModel.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 13/02/2026.
//

import Foundation
import Combine

@MainActor
final class WalletViewerViewModel: ObservableObject {
    @Published var address: String = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
    @Published var selectedChain: Chain = .sepolia
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var summary: WalletSummary?
    @Published var recentAddresses: [String] = []
    @Published var state: WalletViewState = .idle
    @Published var transactions: [WalletTransaction] = []
    @Published var isLoadingTransactions: Bool = false

    private let txService: TransactionHistoryServiceProtocol

    // MARK: - Token Pagination

    /// All tokens fetched from the API (kept private, not rendered directly)
    private var allTokens: [TokenHolding] = []

    /// Tokens currently visible in the UI (paginated slice)
    @Published private(set) var visibleTokens: [TokenHolding] = []

    /// Number of tokens to show per page
    let tokensPageSize: Int = 15

    /// Whether more tokens are available to load
    var hasMoreTokens: Bool {
        visibleTokens.count < allTokens.count
    }

    /// Total token count (for the badge)
    var totalTokenCount: Int {
        allTokens.count
    }

    private let service: WalletViewerServiceProtocol
    private let recentStore: RecentWalletStoreProtocol

    init(
        service: WalletViewerServiceProtocol = WalletViewerService(),
        recentStore: RecentWalletStoreProtocol = RecentWalletStore(),
        txService: TransactionHistoryServiceProtocol = TransactionHistoryService()
    ) {
        self.service = service
        self.recentStore = recentStore
        self.txService = txService
        self.recentAddresses = recentStore.fetch()
    }


    func loadWallet() async {
        errorMessage = nil
        summary = nil
        allTokens = []
        visibleTokens = []

        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard EthereumAddressValidator.isValid(trimmed) else {
            errorMessage = "Invalid wallet address. Must start with 0x and be 42 characters."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await service.fetchWalletSummary(address: trimmed, chain: selectedChain)
            summary = result

            // Store full token list, show first page
            allTokens = result.tokens
            visibleTokens = Array(allTokens.prefix(tokensPageSize))

            recentStore.save(address: trimmed)
            recentAddresses = recentStore.fetch()
            
            await loadTransactions(for: address, chain: selectedChain)

            
        } catch {
            errorMessage = error.localizedDescription
            print("Wallet load error:", error.localizedDescription)
        }
    }

    func loadTransactions(for address: String, chain: Chain) async {
        isLoadingTransactions = true
        defer { isLoadingTransactions = false }

        do {
            transactions = try await txService.fetchTransactions(address: address, chain: chain)
        } catch {
            // Keep silent fallback; do not block main wallet success
            transactions = []
            print("Transaction fetch failed: \(error.localizedDescription)")
        }
    }

    /// Load next page of tokens
    func loadMoreTokens() {
        let currentCount = visibleTokens.count
        guard currentCount < allTokens.count else { return }

        let nextSlice = allTokens.prefix(currentCount + tokensPageSize)
        visibleTokens = Array(nextSlice)
    }

    func selectRecent(_ value: String) {
        address = value
    }

    func clearRecent() {
        recentStore.clear()
        recentAddresses = []
    }
}
