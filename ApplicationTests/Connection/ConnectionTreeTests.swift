//
//  ConnectionTreeTests.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import XCTest
@testable import Application

class ConnectionTreeTests: ApplicationBaseTests {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: Tests
    
    func testThatAddConnectionRequest() {
        /// Given
        let connectionMock = ConnectionMock(url: "https://httpbin.org")
        let connectionRequest = connectionMock.get("get", parameters: nil)
        let sut = ConnectionTree()
        
        /// When
        sut.addConnectionRequest(connectionRequest)
        
        /// Then
        XCTAssertFalse(sut.isEmpty)
    }
    
    func testThatRemoveConnectionRequest() {
        /// Given        
        let connectionMock = ConnectionMock(url: "https://httpbin.org")
        let connectionRequest = connectionMock.get("get", parameters: nil)
        let sut = ConnectionTree()
        
        /// When
        sut.addConnectionRequest(connectionRequest)
        _ = sut.removeConnectionRequest(withRegistration: connectionRequest.identifier)
        
        /// Then
        XCTAssertTrue(sut.isEmpty)
    }
}
