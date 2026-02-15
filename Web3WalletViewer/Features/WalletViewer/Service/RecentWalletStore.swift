//
//  RecentWalletStore.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 14/02/2026.
//

import Foundation

protocol RecentWalletStoreProtocol {
    func fetch() -> [String]
    func save(address: String)
    func clear()
}

final class RecentWalletStore: RecentWalletStoreProtocol {
    private let key = "recent_wallet_addresses"
    private let limit = 5

    func fetch() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    func save(address: String) {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var current = fetch().filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        current.insert(trimmed, at: 0)
        current = Array(current.prefix(limit))
        UserDefaults.standard.set(current, forKey: key)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
