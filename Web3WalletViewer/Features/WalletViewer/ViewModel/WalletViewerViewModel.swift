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
    @Published var address: String = "0x21D25522519fa04f00D296b6Ba38965c4d864C55"
    @Published var selectedChain: Chain = .sepolia
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var summary: WalletSummary?
    @Published var recentAddresses: [String] = []

    private let service: WalletViewerServiceProtocol
    private let recentStore: RecentWalletStoreProtocol

    init(
        service: WalletViewerServiceProtocol = WalletViewerService(),
        recentStore: RecentWalletStoreProtocol = RecentWalletStore()
    ) {
        self.service = service
        self.recentStore = recentStore
        self.recentAddresses = recentStore.fetch()
    }

    func loadWallet() async {
        errorMessage = nil
        summary = nil

        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard EthereumAddressValidator.isValid(trimmed) else {
            errorMessage = "Invalid wallet address. Must start with 0x and be 42 characters."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            summary = try await service.fetchWalletSummary(address: trimmed, chain: selectedChain)
            recentStore.save(address: trimmed)
            recentAddresses = recentStore.fetch()
        } catch {
            errorMessage = error.localizedDescription
            print("Wallet load error:", error.localizedDescription)
        }
    }

    func selectRecent(_ value: String) {
        address = value
    }

    func clearRecent() {
        recentStore.clear()
        recentAddresses = []
    }
}
