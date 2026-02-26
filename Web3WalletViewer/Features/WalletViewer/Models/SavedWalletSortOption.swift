//
//  SavedWalletSortOption.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 15/02/2026.
//

enum SavedWalletSortOption: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case labelAZ = "Label A-Z"
    case favoritesFirst = "Favorites First"
    case chain = "Chain"

    var id: String { rawValue }
}

enum SavedWalletChainFilter: Identifiable, Equatable {
    case all
    case chain(Chain)

    var id: String {
        switch self {
        case .all: return "all"
        case .chain(let c): return "chain_\(c.rawValue)"
        }
    }

    var title: String {
        switch self {
        case .all: return "All Chains"
        case .chain(let c): return c.rawValue
        }
    }

    static var allCases: [SavedWalletChainFilter] {
        [.all] + Chain.allCases.map { .chain($0) }
    }
}
