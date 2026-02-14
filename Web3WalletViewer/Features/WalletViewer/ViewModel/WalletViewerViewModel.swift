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
    @Published var selectedChain: Chain = .sepolia
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var summary: WalletSummary?
    
    //0x21D25522519fa04f00D296b6Ba38965c4d864C55 //Account 1
    @Published var address: String = "0x21D25522519fa04f00D296b6Ba38965c4d864C55" //0x9A7Aee73aBAc219457C8Ee66bdE42Ba5473A8c0a

    private let service: WalletViewerServiceProtocol
    
    init(service: WalletViewerServiceProtocol = WalletViewerService()) {
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
