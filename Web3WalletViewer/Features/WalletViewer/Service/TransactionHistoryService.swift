//
//  TransactionHistoryService.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 15/02/2026.
//

import Foundation

protocol TransactionHistoryServiceProtocol {
    func fetchTransactions(address: String, chain: Chain) async throws -> [WalletTransaction]
}

enum TransactionHistoryServiceError: LocalizedError {
    case badURL
    case requestFailed(Int)
    case invalidResponse
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid transaction API URL."
        case .requestFailed(let code): return "Transaction API failed with status \(code)."
        case .invalidResponse: return "Invalid transaction API response."
        case .decodingFailed: return "Could not decode transactions."
        }
    }
}

private struct CovalentTxResponse: Decodable {
    let data: CovalentTxData?
}
private struct CovalentTxData: Decodable {
    let items: [CovalentTxItem]
}
private struct CovalentTxItem: Decodable {
    let txHash: String?
    let fromAddress: String?
    let toAddress: String?
    let value: String?
    let blockSignedAt: String?

    enum CodingKeys: String, CodingKey {
        case txHash = "tx_hash"
        case fromAddress = "from_address"
        case toAddress = "to_address"
        case value
        case blockSignedAt = "block_signed_at"
    }
}

final class TransactionHistoryService: TransactionHistoryServiceProtocol {
    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared, apiKey: String = AppSecrets.covalentAPIKey) {
        self.session = session
        self.apiKey = apiKey
    }

    func fetchTransactions(address: String, chain: Chain) async throws -> [WalletTransaction] {
        let urlString = "https://api.covalenthq.com/v1/\(chain.covalentChainId)/address/\(address)/transactions_v2/?page-size=15&key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw TransactionHistoryServiceError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw TransactionHistoryServiceError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw TransactionHistoryServiceError.requestFailed(http.statusCode)
        }

        let decoded: CovalentTxResponse
        do {
            decoded = try JSONDecoder().decode(CovalentTxResponse.self, from: data)
        } catch {
            throw TransactionHistoryServiceError.decodingFailed
        }

        let iso = ISO8601DateFormatter()
        let lowerAddress = address.lowercased()

        let txs: [WalletTransaction] = (decoded.data?.items ?? []).compactMap { item in
            guard let hash = item.txHash, !hash.isEmpty else { return nil }
            let from = item.fromAddress ?? ""
            let to = item.toAddress ?? ""
            let incoming = to.lowercased() == lowerAddress

            let valueETH: String = {
                guard let raw = item.value,
                      let formatted = DecimalBalanceFormatter.formatTokenBalance(rawBalance: raw, decimals: 18, maxFractionDigits: 6)
                else { return "0" }
                return formatted
            }()

            return WalletTransaction(
                id: hash.lowercased(),
                hash: hash,
                from: from,
                to: to,
                value: "\(valueETH) \(chain.symbol)",
                timestamp: item.blockSignedAt.flatMap { iso.date(from: $0) },
                isIncoming: incoming,
                chain: chain
            )
        }

        return txs
    }
}
