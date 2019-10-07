//
//  RequestMonitorTests.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import XCTest
@testable import Application

class RequestMonitorTests: ApplicationBaseTests {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: Tests
    
    func testThatSubscribeToStateUpdates() {
        /// Given
        let sut = RequestMonitor()
        let connectionMock = ConnectionMock(url: "https://httpbin.org", requestMonitor: sut)
        let connectionRequest = connectionMock.get("get", parameters: nil)
        var isSubscribeToStateUpdatesInvoked = false
        
        /// When
        sut.subscribeToStateUpdates(connectionRequest) { _ in
            isSubscribeToStateUpdatesInvoked = true
        }
        connectionRequest.resume()
        
        /// Then
        XCTAssertTrue(isSubscribeToStateUpdatesInvoked)
    }
    
    func testThatSubscribeToStateUpdatesShouldStopAfterRequestFinishes() {
        /// Given
        let sut = RequestMonitor()
        let connectionMock = ConnectionMock(url: "https://httpbin.org", requestMonitor: sut)
        let connectionRequest = connectionMock.get("get", parameters: nil)
        var subscribeToStateUpdatesInvocations = [false]
        let subscribeToStateUpdatesExpectedInvocations = [false, true, true]
        
        /// When
        sut.subscribeToStateUpdates(connectionRequest) { _ in
            subscribeToStateUpdatesInvocations.append(true)
        }
        
        connectionRequest.resume()
        connectionRequest.cancel()
        connectionRequest.resume()
        
        /// Then
        XCTAssertEqual(subscribeToStateUpdatesInvocations, subscribeToStateUpdatesExpectedInvocations)
    }
}
