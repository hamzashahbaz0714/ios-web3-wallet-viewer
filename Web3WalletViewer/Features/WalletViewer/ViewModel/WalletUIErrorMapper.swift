//
//  WalletUIErrorMapper.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 15/02/2026.
//

import Foundation

enum WalletUIErrorMapper {
    static func message(for error: Error) -> String {
        if let rpc = error as? RPCClientError {
            switch rpc {
            case .serverStatus: return "Server is busy. Please try again."
            case .transport: return "Network issue. Check your internet and retry."
            case .decodingFailed: return "Unexpected response from network."
            default: return "Something went wrong. Please try again."
            }
        }
        return error.localizedDescription
    }
}
