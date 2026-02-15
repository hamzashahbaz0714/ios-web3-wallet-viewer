//
//  WalletViewState.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 15/02/2026.
//

import Foundation

enum WalletViewState {
    case idle
    case loading
    case loaded(WalletSummary)
    case error(String)
}

