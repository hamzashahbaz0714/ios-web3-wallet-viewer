//
//  TokenAPIModels.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 15/02/2026.
//

import Foundation

// Top-level response
struct CovalentBalancesResponse: Decodable {
    let data: CovalentData?
    let error: Bool?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case data, error
        case errorMessage = "error_message"
    }
}

struct CovalentData: Decodable {
    let items: [CovalentTokenItem]
}

struct CovalentTokenItem: Decodable {
    let contractAddress: String?
    let contractTickerSymbol: String?
    let contractDecimals: Int?
    let balance: String? // big integer in string (raw units)

    enum CodingKeys: String, CodingKey {
        case contractAddress = "contract_address"
        case contractTickerSymbol = "contract_ticker_symbol"
        case contractDecimals = "contract_decimals"
        case balance
    }
}
