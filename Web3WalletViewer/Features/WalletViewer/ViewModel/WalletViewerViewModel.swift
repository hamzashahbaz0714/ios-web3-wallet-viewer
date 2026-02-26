//
//  WalletViewerViewModel.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 13/02/2026.
//
//
//  WalletViewerViewModel.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 13/02/2026.
//

import Foundation
import UIKit
import Combine
import SwiftUI

@MainActor
final class WalletViewerViewModel: ObservableObject {
    @Published var address: String = "0x1111111111111111111111111111111111111111"

    @Published var editNotesInput: String = ""
    @Published var editLabelInput: String = ""
    @Published var editingWallet: SavedWallet?
    @Published var walletChainFilter: SavedWalletChainFilter = .all
    @Published var walletSort: SavedWalletSortOption = .recent
    @Published var selectedChain: Chain = .sepolia
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var summary: WalletSummary?
    @Published var recentAddresses: [String] = []
    @Published var state: WalletViewState = .idle
    @Published var transactions: [WalletTransaction] = []
    @Published var isLoadingTransactions: Bool = false

    @Published var savedWallets: [SavedWallet] = []
    @Published var walletSearchQuery: String = ""
    @Published var showSaveSheet: Bool = false
    @Published var autoLoadSavedWalletOnSelect: Bool = true {
        didSet { UserDefaults.standard.set(autoLoadSavedWalletOnSelect, forKey: Self.autoLoadPrefKey) }
    }
    @Published var saveLabelInput: String = ""


    private let savedWalletStore: SavedWalletStoreProtocol

    private static let autoLoadPrefKey = "auto_load_saved_wallet_on_select_v1"
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
        txService: TransactionHistoryServiceProtocol = TransactionHistoryService(),
        savedWalletStore: SavedWalletStoreProtocol = SavedWalletStore()
    ) {
        self.service = service
        self.recentStore = recentStore
        self.txService = txService
        self.savedWalletStore = savedWalletStore
        self.recentAddresses = recentStore.fetch()
        self.savedWallets = savedWalletStore.fetch()
        autoLoadSavedWalletOnSelect = UserDefaults.standard.object(forKey: Self.autoLoadPrefKey) as? Bool ?? true
    }



    func loadWallet() async {
        address = WalletInputParser.extractAddress(from: address)

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
    
    //for saving wallet
    func saveCurrentWallet() {
        let normalized = WalletInputParser.extractAddress(from: address)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard EthereumAddressValidator.isValid(normalized) else {
            errorMessage = "Please enter a valid wallet address before saving."
            return
        }

        let label = saveLabelInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Wallet \(savedWallets.count + 1)"
            : saveLabelInput.trimmingCharacters(in: .whitespacesAndNewlines)

        let item = SavedWallet(label: label, address: normalized, chain: selectedChain)
        savedWalletStore.save(item)
        savedWallets = savedWalletStore.fetch()

        // keep UI in sync
        address = normalized
        saveLabelInput = ""
        showSaveSheet = false
    }


    func selectSavedWallet(_ wallet: SavedWallet) {
        address = wallet.address
        selectedChain = wallet.chain
    }

    func deleteSavedWallet(_ wallet: SavedWallet) {
        savedWalletStore.delete(id: wallet.id)
        savedWallets = savedWalletStore.fetch()
    }

    var filteredSavedWallets: [SavedWallet] {
        let q = walletSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return savedWallets }
        return savedWallets.filter {
            $0.label.lowercased().contains(q) || $0.address.lowercased().contains(q)
        }
    }

}


extension WalletViewerViewModel {

    
    func reloadSavedWallets() {
        savedWallets = savedWalletStore.fetch()
    }


    func toggleFavorite(_ wallet: SavedWallet) {
        var updated = wallet
        updated.isFavorite.toggle()
        updated.updatedAt = Date()
        savedWalletStore.update(updated)
        reloadSavedWallets()
    }


    func beginEdit(_ wallet: SavedWallet) {
        editingWallet = wallet
        editLabelInput = wallet.label
        editNotesInput = wallet.notes
    }


    func cancelEdit() {
        editingWallet = nil
        editLabelInput = ""
        editNotesInput = ""
    }


    func saveEdit() {
        guard var wallet = editingWallet else { return }
        let trimmedLabel = editLabelInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLabel.isEmpty else { return }

        wallet.label = trimmedLabel
        wallet.notes = editNotesInput.trimmingCharacters(in: .whitespacesAndNewlines)
        wallet.updatedAt = Date()

        savedWalletStore.update(wallet)
        cancelEdit()
        reloadSavedWallets()
    }


    func copyAddress(_ wallet: SavedWallet) {
        UIPasteboard.general.string = wallet.address
    }
        
        


    func explorerURL(for wallet: SavedWallet) -> URL? {
        switch wallet.chain {
        case .ethereumMainnet:
            return URL(string: "https://etherscan.io/address/\(wallet.address)")
        case .sepolia:
            return URL(string: "https://sepolia.etherscan.io/address/\(wallet.address)")
        }
    }

    var displayedSavedWallets: [SavedWallet] {
        let q = walletSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var result = savedWallets

        switch walletChainFilter {
        case .all:
            break
        case .chain(let chain):
            result = result.filter { $0.chain == chain }
        }

        if !q.isEmpty {
            result = result.filter {
                $0.label.lowercased().contains(q) ||
                $0.address.lowercased().contains(q) ||
                $0.notes.lowercased().contains(q)
            }
        }

        switch walletSort {
        case .recent:
            result.sort { $0.updatedAt > $1.updatedAt }
        case .labelAZ:
            result.sort { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
        case .favoritesFirst:
            result.sort {
                if $0.isFavorite == $1.isFavorite { return $0.updatedAt > $1.updatedAt }
                return $0.isFavorite && !$1.isFavorite
            }
        case .chain:
            result.sort { $0.chain.rawValue < $1.chain.rawValue }
        }

        return result
    }

}
