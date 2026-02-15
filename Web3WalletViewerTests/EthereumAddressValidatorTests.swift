//
//  EthereumAddressValidatorTests.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 14/02/2026.
//

import XCTest
@testable import Web3WalletViewer

final class EthereumAddressValidatorTests: XCTestCase {

    func testValidAddress() {
        let value = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
        XCTAssertTrue(EthereumAddressValidator.isValid(value))
    }

    func testInvalidAddressMissing0x() {
        let value = "d8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
        XCTAssertFalse(EthereumAddressValidator.isValid(value))
    }

    func testInvalidAddressWrongLength() {
        XCTAssertFalse(EthereumAddressValidator.isValid("0x123"))
    }
}
