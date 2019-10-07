//
//  PersistentConnectionTests.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import XCTest
@testable import Application

class PersistentConnectionTests: ApplicationBaseTests {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: Tests

    func testThatDeletePath() {
        /// Given
        let expectation = self.expectation(description: "Delete Path Expectation")
        let serverInfo = ServerInfo(host: "httpbin.org", isSecure: true)
        let sut = PersistentConnection(serverInfo: serverInfo)
        let expectedPath = "/delete/1"
        let connectionRequest: ConnectionRequest
        
        /// When
        connectionRequest = sut.get("delete/1").responseJSON({ _, _ in
            expectation.fulfill()
        })
        
        /// Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertEqual(connectionRequest.url?.path, expectedPath)
    }

    func testThatGetPath() {
        /// Given
        let expectation = self.expectation(description: "Get Expectation")
        let serverInfo = ServerInfo(host: "httpbin.org", isSecure: true)
        let sut = PersistentConnection(serverInfo: serverInfo)
        let expectedPath = "/get"
        let connectionRequest: ConnectionRequest
        
        /// When
        connectionRequest = sut.get("get").responseJSON({ _, _ in
            expectation.fulfill()
        })
        
        /// Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertEqual(connectionRequest.url?.path, expectedPath)
    }
    
    func testThatGetParameters() {
        /// Given
        let expectation = self.expectation(description: "Get Parameters Expectation")
        let parameters = ["foo": "bar", "xyz": "zxy"]
        let serverInfo = ServerInfo(host: "httpbin.org", isSecure: true)
        let sut = PersistentConnection(serverInfo: serverInfo)
        let path = "get"
        let connectionRequest: ConnectionRequest
        let expectedQuery = "foo=bar&xyz=zxy"
        
        /// When
        connectionRequest = sut.get(path, parameters: parameters).responseJSON({ _, _ in
            expectation.fulfill()
        })
        
        /// Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertEqual(connectionRequest.url?.query, expectedQuery)
    }
    
    func testThatObserveReachabilityStatusChanges() {
        /// Given
        let expectation = self.expectation(description: "PersistentConnectionTests testThatObserveReachabilityStatusChanges()")
        let serverInfo = ServerInfo(host: "httpbin.org", isSecure: true)
        let sut = PersistentConnection(serverInfo: serverInfo)
        var connectionStatus: ConnectionStatus?
        
        /// When
        sut.observeReachabilityStatusChanges({
            connectionStatus = $0
            expectation.fulfill()
        })
        
        /// Then
        self.waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertNotNil(connectionStatus)
    }
    
    func testThatSendPath() {
        /// Given
        let expectation = self.expectation(description: "Send Path Expectation")
        let serverInfo = ServerInfo(host: "httpbin.org", isSecure: true)
        let sut = PersistentConnection(serverInfo: serverInfo)
        let expectedPath = "/post"
        let connectionRequest: ConnectionRequest
        let parameters: ConnectionParameters = ["foo": "bar", "xyz": 1]
        
        /// When
        connectionRequest = sut.send(parameters, path: "post", action: .post).responseJSON({ _, _ in
            expectation.fulfill()
        })
        
        /// Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertEqual(connectionRequest.url?.path, expectedPath)
    }
    
    func testThatSendParameters() {
        /// Given
        let expectation = self.expectation(description: "Send Path Expectation")
        let serverInfo = ServerInfo(host: "httpbin.org", isSecure: true)
        let sut = PersistentConnection(serverInfo: serverInfo)
        let connectionRequest: ConnectionRequest
        let parameters: ConnectionParameters = ["foo": "bar"]
        let expectedParameters = "{\"foo\":\"bar\"}"
        
        /// When
        connectionRequest = sut.send(parameters, path: "post", action: .post).responseJSON({ _, _ in
            expectation.fulfill()
        })
        
        /// Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertEqual(String(data: connectionRequest.httpBody!, encoding: .utf8), expectedParameters)
    }

    func testThatRemoveHeaderForKey() {
        /// Given
        let serverInfo = ServerInfo(host: "httpbin.org", isSecure: true)
        let sut = PersistentConnection(serverInfo: serverInfo)

        /// When
        sut.setHeader("foo", forKey: "bar")
        sut.removeHeader(forKey: "bar")

        /// Then
        XCTAssertNil(sut.header(forKey: "bar"))
    }

    func testThatSetHeaderForKey() {
        /// Given
        let serverInfo = ServerInfo(host: "httpbin.org", isSecure: true)
        let sut = PersistentConnection(serverInfo: serverInfo)

        /// When
        sut.setHeader("foo", forKey: "bar")

        /// Then
        XCTAssertNotNil(sut.header(forKey: "bar"))
    }
}
