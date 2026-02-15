//
//  TokenBalanceService.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 15/02/2026.
//

import Foundation

protocol TokenBalanceServiceProtocol {
    func fetchTokenBalances(address: String, chain: Chain) async throws -> [TokenHolding]
}

enum TokenBalanceServiceError: LocalizedError {
    case badURL
    case requestFailed(Int)
    case invalidResponse
    case apiError(String)
    case decodingFailed
    case unsupported

    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid token API URL."
        case .requestFailed(let code): return "Token API failed with status \(code)."
        case .invalidResponse: return "Invalid token API response."
        case .apiError(let msg): return msg
        case .decodingFailed: return "Could not decode token balances."
        case .unsupported: return "This network is not supported for token balances."
        }
    }
}

final class TokenBalanceService: TokenBalanceServiceProtocol {
    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared, apiKey: String = AppSecrets.covalentAPIKey) {
        self.session = session
        self.apiKey = apiKey
    }

    func fetchTokenBalances(address: String, chain: Chain) async throws -> [TokenHolding] {
        // If needed, you can choose to support only mainnet now
        // guard chain == .ethereumMainnet else { throw TokenBalanceServiceError.unsupported }

        let urlString = "https://api.covalenthq.com/v1/\(chain.covalentChainId)/address/\(address)/balances_v2/?nft=false&no-nft-fetch=true&key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw TokenBalanceServiceError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw TokenBalanceServiceError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw TokenBalanceServiceError.requestFailed(http.statusCode)
        }

        let decoded: CovalentBalancesResponse
        do {
            decoded = try JSONDecoder().decode(CovalentBalancesResponse.self, from: data)
        } catch {
            throw TokenBalanceServiceError.decodingFailed
        }

        if decoded.error == true {
            throw TokenBalanceServiceError.apiError(decoded.errorMessage ?? "Unknown token API error.")
        }

        guard let items = decoded.data?.items else {
            return []
        }

        print(items.first)
        // Filter usable ERC-20-ish token rows:
        // - has symbol
        // - has decimals and balance
        // - non-zero balance only (for cleaner UI)
        let mapped: [TokenHolding] = items.compactMap { item in
            guard
                let symbol = item.contractTickerSymbol, !symbol.isEmpty,
                let contract = item.contractAddress, !contract.isEmpty,
                let decimals = item.contractDecimals,
                let rawBalance = item.balance
            else {
                return nil
            }

            guard let formatted = DecimalBalanceFormatter.formatTokenBalance(
                rawBalance: rawBalance,
                decimals: decimals
            ) else {
                return nil
            }

            // Hide zero balances (optional)
            if formatted == "0" || formatted == "0.0" || formatted == "0.00" {
                return nil
            }

            return TokenHolding(
                id: contract.lowercased(),
                symbol: symbol,
                amount: formatted,
                contractAddress: contract,
                decimals: decimals
            )
        }

        // Optional: sort by symbol for stable UI
        return mapped.sorted { $0.symbol.localizedCaseInsensitiveCompare($1.symbol) == .orderedAscending }
    }
}
