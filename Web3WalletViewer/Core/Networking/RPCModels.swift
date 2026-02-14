//
//  RPCModels.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 14/02/2026.
//
import Foundation

struct JSONRPCRequest<P: Encodable>: Encodable {
    let jsonrpc: String = "2.0"
    let method: String
    let params: P
    let id: Int
}

struct JSONRPCResponse<R: Decodable>: Decodable {
    let jsonrpc: String
    let id: JSONRPCID?
    let result: R?
    let error: JSONRPCErrorObject?
}

enum JSONRPCID: Decodable {
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
            return
        }
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }
        throw DecodingError.typeMismatch(
            JSONRPCID.self,
            .init(codingPath: decoder.codingPath, debugDescription: "Unsupported id type")
        )
    }
}

struct JSONRPCErrorObject: Decodable, Error {
    let code: Int
    let message: String
}
