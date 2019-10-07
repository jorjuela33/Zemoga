//
//  ConnectionRequestsTests.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import XCTest
@testable import Application

private class ConnectionDelegateHandler: ConnectionRequestDelegate {
    private let connectionRequestDidCancelCallback: ((ConnectionRequest) -> Void)?
    private let connectionRequestDidFinishCallback: ((ConnectionRequest) -> Void)?
    private let connectionRequestDidResumeCallback: ((ConnectionRequest) -> Void)?
    private let connectionRequestDidSuspendCallback: ((ConnectionRequest) -> Void)?
    
    // MARK: Initialization
    
    init(
        connectionRequestDidCancelCallback: ((ConnectionRequest) -> Void)? = nil,
        connectionRequestDidFinishCallback: ((ConnectionRequest) -> Void)? = nil,
        connectionRequestDidResumeCallback: ((ConnectionRequest) -> Void)? = nil,
        connectionRequestDidSuspendCallback: ((ConnectionRequest) -> Void)? = nil
        ) {
        
        self.connectionRequestDidCancelCallback = connectionRequestDidCancelCallback
        self.connectionRequestDidFinishCallback = connectionRequestDidFinishCallback
        self.connectionRequestDidResumeCallback = connectionRequestDidResumeCallback
        self.connectionRequestDidSuspendCallback = connectionRequestDidSuspendCallback
    }
    
    // MARK: ConnectionRequestDelegate
    
    func connectionRequestDidCancel(_ connectionRequest: ConnectionRequest) {
        connectionRequestDidCancelCallback?(connectionRequest)
    }
    
    func connectionRequestDidFinish(_ connectionRequest: ConnectionRequest) {
        connectionRequestDidFinishCallback?(connectionRequest)
    }
    
    func connectionRequestDidResume(_ connectionRequest: ConnectionRequest) {
        connectionRequestDidResumeCallback?(connectionRequest)
    }
    
    func connectionRequestDidSuspend(_ connectionRequest: ConnectionRequest) {
        connectionRequestDidSuspendCallback?(connectionRequest)
    }
}

class ConnectionRequestsTests: ApplicationBaseTests {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: Tests

    func testThatDelegateShouldInvokeDidCancel() {
        /// Given
        let expectation = self.expectation(description: "DidCancel Expectation")
        let connectionDelegateHandler: ConnectionDelegateHandler
        let serverInfo = ServerInfo(host: "httpbin.org/", isSecure: true)
        let persistentConnection = PersistentConnection(serverInfo: serverInfo)
        let sut = persistentConnection.get("get")
        var isDidCancelInvoked = false
        
        /// When
        connectionDelegateHandler = ConnectionDelegateHandler (connectionRequestDidCancelCallback: { _ in
            isDidCancelInvoked = true
            expectation.fulfill()
        })
        sut.delegate = connectionDelegateHandler
        sut.cancel()
        
        /// Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertTrue(isDidCancelInvoked)
    }
    
    func testThatDelegateShouldInvokeDidResume() {
        /// Given
        let expectation = self.expectation(description: "DidResume Expectation")
        let connectionDelegateHandler: ConnectionDelegateHandler
        let serverInfo = ServerInfo(host: "httpbin.org/", isSecure: true)
        let persistentConnection = PersistentConnection(serverInfo: serverInfo, startRequestsImmediately: false)
        let sut = persistentConnection.get("get")
        var isDidResumeInvoked = false
        
        /// When
        connectionDelegateHandler = ConnectionDelegateHandler (connectionRequestDidResumeCallback: { _ in
            isDidResumeInvoked = true
            expectation.fulfill()
        })
        sut.delegate = connectionDelegateHandler
        sut.resume()
        
        /// Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertTrue(isDidResumeInvoked)
    }
    
    func testThatDelegateShouldInvokeDidSuspend() {
        /// Given
        let expectation = self.expectation(description: "DidSuspend Expectation")
        let connectionDelegateHandler: ConnectionDelegateHandler
        let serverInfo = ServerInfo(host: "httpbin.org/", isSecure: true)
        let persistentConnection = PersistentConnection(serverInfo: serverInfo)
        let sut = persistentConnection.get("get")
        var isDidSuspendInvoked = false
        
        /// When
        connectionDelegateHandler = ConnectionDelegateHandler (connectionRequestDidSuspendCallback: { _ in
            isDidSuspendInvoked = true
            expectation.fulfill()
        })
        sut.delegate = connectionDelegateHandler
        sut.suspend()
        
        /// Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertTrue(isDidSuspendInvoked)
    }
    
    func testThatCompletionShouldBeInvoked() {
        /// Given
        let expectation = self.expectation(description: "Completion Block Expectation")
        let serverInfo = ServerInfo(host: "httpbin.org/", isSecure: true)
        let persistentConnection = PersistentConnection(serverInfo: serverInfo, startRequestsImmediately: false)
        let sut = persistentConnection.get("get")
        var isCompletionInvoked = false
        
        /// When
        sut.completionCallback = {
            isCompletionInvoked = true
            expectation.fulfill()
        }
        sut.resume()
        
        /// Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertTrue(isCompletionInvoked)
    }
    
    func testThatCompletionShouldBeInvokedOnCancellation() {
        /// Given
        let expectation = self.expectation(description: "Completion Block Expectation")
        let serverInfo = ServerInfo(host: "httpbin.org/", isSecure: true)
        let persistentConnection = PersistentConnection(serverInfo: serverInfo)
        let sut = persistentConnection.get("get")
        var isCompletionInvoked = false
        
        /// When
        sut.completionCallback = {
            isCompletionInvoked = true
            expectation.fulfill()
        }
        sut.cancel()
        
        /// Then
        waitForExpectations(timeout: expectationTimeout, handler: nil)
        XCTAssertTrue(isCompletionInvoked)
    }
}
