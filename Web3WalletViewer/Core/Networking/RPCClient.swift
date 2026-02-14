//
//  RPCClient.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 14/02/2026.
//

import Foundation

protocol RPCClientProtocol {
    func call<P: Encodable, R: Decodable>(
        url: URL,
        method: String,
        params: P
    ) async throws -> R
}

enum RPCClientError: LocalizedError {
    case invalidHTTPResponse
    case serverStatus(Int)
    case rpcError(code: Int, message: String)
    case emptyResult
    case decodingFailed
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidHTTPResponse:
            return "Invalid response from server."
        case .serverStatus(let code):
            return "Server error (HTTP \(code))."
        case .rpcError(_, let message):
            return "RPC error: \(message)"
        case .emptyResult:
            return "No data returned from RPC."
        case .decodingFailed:
            return "Could not parse server response."
        case .transport(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

final class RPCClient: RPCClientProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func call<P: Encodable, R: Decodable>(
        url: URL,
        method: String,
        params: P
    ) async throws -> R {
        let requestBody = JSONRPCRequest(method: method, params: params, id: Int.random(in: 1...999999))

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw RPCClientError.transport(error)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw RPCClientError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw RPCClientError.invalidHTTPResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw RPCClientError.serverStatus(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(JSONRPCResponse<R>.self, from: data)

            if let rpcError = decoded.error {
                throw RPCClientError.rpcError(code: rpcError.code, message: rpcError.message)
            }

            guard let result = decoded.result else {
                throw RPCClientError.emptyResult
            }

            return result
        } catch let clientErr as RPCClientError {
            throw clientErr
        } catch {
            throw RPCClientError.decodingFailed
        }
    }
}
