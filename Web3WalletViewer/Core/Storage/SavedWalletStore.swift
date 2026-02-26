//
//  SavedWalletStore.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 15/02/2026.
//
import Foundation

protocol SavedWalletStoreProtocol {
    func fetch() -> [SavedWallet]
    func save(_ wallet: SavedWallet)
    func delete(id: UUID)
    func update(_ wallet: SavedWallet)
    func clearAll()
    func markUsed(id: UUID)
}

final class SavedWalletStore: SavedWalletStoreProtocol {
    private let key = "saved_wallets_v2"

    func fetch() -> [SavedWallet] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let wallets = try? JSONDecoder().decode([SavedWallet].self, from: data) else {
            return []
        }
        return wallets.sorted { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite && !rhs.isFavorite }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    func save(_ wallet: SavedWallet) {
        var all = fetch()
        // unique by address + chain
        if let idx = all.firstIndex(where: { $0.address.lowercased() == wallet.address.lowercased() && $0.chain == wallet.chain }) {
            var merged = wallet
            // preserve identity
            merged = SavedWallet(id: all[idx].id, label: merged.label, address: merged.address, chain: merged.chain, notes: merged.notes, tags: merged.tags, isFavorite: all[idx].isFavorite, createdAt: all[idx].createdAt, updatedAt: Date(), lastUsedAt: all[idx].lastUsedAt)
            merged.updatedAt = Date()
            all[idx] = merged
        } else {
            var new = wallet
            new.updatedAt = Date()
            all.insert(new, at: 0)
        }
        persist(all)
    }

    func delete(id: UUID) {
        var all = fetch()
        all.removeAll { $0.id == id }
        persist(all)
    }

    func update(_ wallet: SavedWallet) {
        var all = fetch()
        guard let idx = all.firstIndex(where: { $0.id == wallet.id }) else { return }
        var updated = wallet
        updated.updatedAt = Date()
        all[idx] = updated
        persist(all)
    }

    func clearAll() {
        persist([])
    }

    func markUsed(id: UUID) {
        var all = fetch()
        guard let idx = all.firstIndex(where: { $0.id == id }) else { return }
        all[idx].lastUsedAt = Date()
        all[idx].updatedAt = Date()
        persist(all)
    }

    private func persist(_ wallets: [SavedWallet]) {
        if let data = try? JSONEncoder().encode(wallets) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
