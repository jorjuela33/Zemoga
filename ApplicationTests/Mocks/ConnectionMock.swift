//
//  ConnectionMock.swift
//  ApplicationTests
//
//  Created by Jorge Orjuela on 10/6/19.
//

import Alamofire
@testable import Application

typealias MockedJSONResponse = (Any?, Error?)

class ConnectionRequestMock: ConnectionRequest {
    private let responseJSON: MockedJSONResponse?

    // MARK: Initialization

    init(dataRequest: DataRequest, requestMonitor: RequestMonitor, responseJSON: MockedJSONResponse?) {
        self.responseJSON = responseJSON
        super.init(dataRequest: dataRequest, requestMonitor: requestMonitor)
    }

    // MARK: Overridden methods

    override func response<T: Decodable>(_ callback: @escaping (T?, Error?) -> Void) -> Self {
        return self
    }

    override func responseJSON(_ callback: @escaping ConnectionRequest.ResponseJSONCallback) -> Self {
        if let responseJSON = responseJSON {
            callback(responseJSON.0, responseJSON.1)
        }
        return self
    }
}

class ConnectionMock: Connection {
    private let requestMonitor: RequestMonitor
    private let url: String
    private var responseJSON: MockedJSONResponse?
    private let session = SessionManager(configuration: .ephemeral)

    var action: Action?
    var authToken = ""
    var isGetInvoked = false
    var headers: [String: String] = [:]
    var parameters: ConnectionParameters = [:]
    var path = ""

    // MARK: Initializaters

    init(url: String, requestMonitor: RequestMonitor = RequestMonitor(), startRequestsImmediately: Bool = false) {
        self.requestMonitor = requestMonitor
        self.session.startRequestsImmediately = startRequestsImmediately
        self.url = url
    }

    // MARK: Connection

    func authenticate(_ authToken: String) -> Self {
        self.authToken = authToken
        return self
    }

    func isOnline() -> Bool {
        return true
    }

    @discardableResult
    func delete(_ path: String, headers: [String : String]) -> ConnectionRequest {
        self.path = path
        let dataRequest = session.request("\(url)/\(path)", method: .delete)
        return ConnectionRequestMock(dataRequest: dataRequest, requestMonitor: requestMonitor, responseJSON: responseJSON)
    }

    func observeReachabilityStatusChanges(_ callback: @escaping ConnectionStatusChangesCallback) -> EventRegistrationHandle {
        return 0
    }

    @discardableResult
    func get(_ path: String, parameters: ConnectionParameters?, headers: [String : String]) -> ConnectionRequest {
        self.isGetInvoked = true
        self.parameters = parameters ?? [:]
        self.path = path
        let dataRequest = session.request("\(url)/\(path)")
        return ConnectionRequestMock(dataRequest: dataRequest, requestMonitor: requestMonitor, responseJSON: responseJSON)
    }

    func header(forKey key: String) -> String? {
        return headers[key]
    }

    @discardableResult
    func send(_ parameters: ConnectionParameters, path: String, action: Action, headers: [String : String]) -> ConnectionRequest {
        self.action = action
        self.path = path
        self.parameters = parameters
        let dataRequest = session.request("\(url)/\(path)", method: .post, parameters: parameters, encoding: JSONEncoding())
        return ConnectionRequestMock(dataRequest: dataRequest, requestMonitor: requestMonitor, responseJSON: responseJSON)
    }

    func removeHeader(forKey key: String) {
        headers.removeValue(forKey: key)
    }

    func removeObserverWithHandle(_ handle: EventRegistrationHandle) {

    }

    func setHeader(_ header: String, forKey key: String) {
        headers[key] = header
    }

    // MARK: Instance methods

    /// adds a dummy response for every request
    func addResponseJSON(_ response: MockedJSONResponse) {
        self.responseJSON = response
    }
}

