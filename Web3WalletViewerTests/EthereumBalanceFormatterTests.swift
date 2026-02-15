//
//  EthereumBalanceFormatterTests.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 14/02/2026.
//

import XCTest
@testable import Web3WalletViewer

final class EthereumBalanceFormatterTests: XCTestCase {

    func testWeiHexToEth() {
        // 1 ETH in wei = 0xde0b6b3a7640000
        let hex = "0xde0b6b3a7640000"
        let result = EthereumBalanceFormatter.ethString(fromHexWei: hex)
        XCTAssertEqual(result, "1")
    }

    func testInvalidHex() {
        let result = EthereumBalanceFormatter.ethString(fromHexWei: "0xZZ")
        XCTAssertNil(result)
    }
}
