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
    @Published var address: String = ""
    @Published var selectedChain: Chain = .sepolia
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var summary: WalletSummary?
    
    private let service: WalletViewerServiceProtocol
    
    init(service: WalletViewerServiceProtocol = MockWalletViewerService()) {
        self.service = service
    }
    
    func loadWallet() async {
        errorMessage = nil
        summary = nil
        
        guard EthereumAddressValidator.isValid(address) else {
            errorMessage = "Invalid wallet address. Must start with 0x and be 42 characters."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            summary = try await service.fetchWalletSummary(address: address, chain: selectedChain)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
