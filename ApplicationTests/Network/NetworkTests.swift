//
//  NetworkTests.swift
//  ApplicationTests
//
//  Created by Jorge Orjuela on 10/6/19.
//

import Domain
import XCTest
@testable import Application

class NetworkTests: ApplicationBaseTests {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: Tests

    func testThatDeletePostPath() {
       /// Given
       let connectionMock = ConnectionMock(url: "https://httpbin.org")
       let expectedPath = "posts/1"
       let sut = NetworkManager(connection: connectionMock)

       /// When
       _ = sut.deletePost(withID: 1, withCallback: { _ in })

       /// Then
       XCTAssertEqual(connectionMock.path, expectedPath)
    }

    func testThatRetrievePosts() {
        /// Given
        let connectionMock = ConnectionMock(url: "https://httpbin.org")
        let sut = NetworkManager(connection: connectionMock)

        /// When
        _ = sut.retrievePosts(withCallback: { _ in })

        /// Then
        XCTAssertTrue(connectionMock.isGetInvoked)
    }

    func testThatRetrievePostsPath() {
        /// Given
        let connectionMock = ConnectionMock(url: "https://httpbin.org")
        let expectedPath = "posts"
        let sut = NetworkManager(connection: connectionMock)

        /// When
        _ = sut.retrievePosts(withCallback: { _ in })

        /// Then
        XCTAssertEqual(connectionMock.path, expectedPath)
    }
}
