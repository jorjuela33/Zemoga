//
//  TrackedConnectionRequestTests.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import XCTest
@testable import Application

class TrackedConnectionRequestTests: ApplicationBaseTests {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: Tests
    
    func testThatSetIsActive() {
        /// Given
        let connectionMock = ConnectionMock(url: "https://httpbin.org")
        let connectionRequest = connectionMock.get("get", parameters: nil)
        let newSut: TrackedConnectionRequest
        let sut = TrackedConnectionRequest(
            id: 0,
            connectionRequest: connectionRequest,
            isActive: false,
            isComplete: false,
            lastUse: Date().timeIntervalSinceNow
        )
        
        /// When
        newSut = sut.setIsActive(true)
        
        /// Then
        XCTAssertTrue(newSut.isActive)
    }
    
    func testThatSetComplete() {
        /// Given
        let connectionMock = ConnectionMock(url: "https://httpbin.org")
        let connectionRequest = connectionMock.get("get", parameters: nil)
        let newSut: TrackedConnectionRequest
        let sut = TrackedConnectionRequest(
            id: 0,
            connectionRequest: connectionRequest,
            isActive: false,
            isComplete: false,
            lastUse: Date().timeIntervalSinceNow
        )
        
        /// When
        newSut = sut.setComplete()
        
        /// Then
        XCTAssertTrue(newSut.isComplete)
    }
    
    func testThatSetUpdateLastUse() {
        /// Given
        let expectedDate = Date().timeIntervalSinceNow
        let connectionMock = ConnectionMock(url: "https://httpbin.org")
        let connectionRequest = connectionMock.get("get", parameters: nil)
        let newSut: TrackedConnectionRequest
        let sut = TrackedConnectionRequest(
            id: 0,
            connectionRequest: connectionRequest,
            isActive: false,
            isComplete: false,
            lastUse: Date().timeIntervalSinceNow
        )
        
        /// When
        newSut = sut.updateLastUse(expectedDate)
        
        /// Then
        XCTAssertEqual(newSut.lastUse, expectedDate)
    }
}
