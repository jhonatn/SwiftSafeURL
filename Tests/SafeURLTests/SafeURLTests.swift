//
//  SafeURLTests.swift
//  
//
//  Created by Jhonatan A. on 1/08/22.
//

import XCTest
import class Foundation.Bundle
@testable import SafeURL
@testable import SafeURLLintFramework

// safeurl:warn

final class SafeURLTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _safeURLRuntimeInTestMode = true
    }
    
    func assertScan(code codeString: String, shouldFail: Bool) {
        let validityMessage = shouldFail ? " not" : ""
        do {
            let scanInfo = SafeURLScanInfo(filePath: "", fileContent: codeString)
            let scanResult = try SafeURLKit.scan(scanInfo)
            XCTAssertEqual(
                shouldFail,
                !scanResult.isEmpty,
                "Code should\(validityMessage) be valid but scanner said otherwise: \"\(codeString)\""
            )
        } catch {
            XCTFail("Problem while scanning test contents: \(error)")
        }
    }
    
    func testURLScanningValidURLs() throws {
        _ = URL(safeString: "127.0.0.1")
        _ = URL(safeString: "localhost")
        _ = URL(safeString: "http://google.com")
        _ = URL(safeString: "https://google.com")
        _ = URL(safeString: "git@github.com:apple/swift.git")
        _ = URL(safeString: "someapp://intentUrl")
        [
            #"URL(safeString: "127.0.0.1")"#,
            #"URL(safeString: "localhost")"#,
            #"URL(safeString: "http://google.com")"#,
            #"URL(safeString: "https://google.com")"#,
            #"URL(safeString: "git@github.com:apple/swift.git")"#,
            #"URL(safeString: "someapp://intentUrl")"#,
        ].forEach { assertScan(code:$0, shouldFail: false) }
    }
    
    func testURLScanningInvalidInputs() throws {
        _ = URL(safeString: "")
        _ = URL(safeString: "https://google. com")
        _ = URL(safeString: "bjigigj894j8044qf@Q#C$T@B^UN&I$")
        [
            #"URL(safeString: "")"#,
            #"URL(safeString: "https://google. com")"#,
            #"URL(safeString: "bjigigj894j8044qf@Q#C$T@B^UN&I$")"#,
        ].forEach { assertScan(code:$0, shouldFail: true) }
    }
    
    func testURLScanningIncompatibleInputs() throws {
        _ = URL(safeString: "http://\u{1F600}.test")
        [
            #"URL(safeString: "http://\u{1F600}.test")"#,
        ].forEach { assertScan(code:$0, shouldFail: true) }
    }
    
    override func tearDown() {
        super.tearDown()
        _safeURLRuntimeInTestMode = false
    }
}
