//
//  Connection.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Alamofire

typealias ConnectionHeaders = [String: String]
typealias ConnectionParameters = [String: Any]
typealias ConnectionRequestRegistration = Int64
typealias ConnectionStatusChangesCallback = (ConnectionStatus) -> Void
typealias JSONObject = [String: Any]

enum Action: String {
    case post = "POST"
    case put = "PUT"
}

enum ConnectionStatus {
    case notReachable
    case reachable

    // MARK: Initializers

    fileprivate init(status: NetworkReachabilityManager.NetworkReachabilityStatus) {
        switch status {
        case .notReachable, .unknown: self = .notReachable
        case .reachable: self = .reachable
        }
    }
}

protocol Connection {
    func header(forKey key: String) -> String?
    func removeHeader(forKey key: String)
    func removeObserverWithHandle(_ handle: EventRegistrationHandle)
    func setHeader(_ header: String, forKey key: String)

    @discardableResult
    func delete(_ path: String, headers: [String: String]) -> ConnectionRequest

    @discardableResult
    func get(_ path: String, parameters: ConnectionParameters?, headers: [String: String]) -> ConnectionRequest

    @discardableResult
    func observeReachabilityStatusChanges(_ callback: @escaping ConnectionStatusChangesCallback) -> EventRegistrationHandle

    func send(_ parameters: ConnectionParameters, path: String, action: Action, headers: [String: String]) -> ConnectionRequest
}

extension Connection {

    @discardableResult
    func delete(_ path: String) -> ConnectionRequest {
        return delete(path, headers: [:])
    }

    @discardableResult
    func get(_ path: String) -> ConnectionRequest {
        return get(path, parameters: nil, headers: [:])
    }

    @discardableResult
    func get(_ path: String, parameters: ConnectionParameters?) -> ConnectionRequest {
        return get(path, parameters: parameters, headers: [:])
    }

    @discardableResult
    func get(_ path: String, headers: [String: String]) -> ConnectionRequest {
        return get(path, parameters: nil, headers: headers)
    }

    @discardableResult
    func send(_ parameters: ConnectionParameters, path: String, action: Action) -> ConnectionRequest {
        return send(parameters, path: path, action: action, headers: [:])
    }
}

final class PersistentConnection: Connection {
    private let callbackQueue = DispatchQueue.main
    private let eventCounter = AtomicNumber.default
    private let eventTree = EventTree()
    private let reachabilityManager: NetworkReachabilityManager?
    private let requestMonitor: RequestMonitor
    private let serverInfo: ServerInfo
    private let session: SessionManager
    private let trackedConnectionRequestManager: TrackedConnectionRequestManager

    private lazy var defaultHTTPHeaders: HTTPHeaders = {
        var defaultHTTPHeaders = SessionManager.defaultHTTPHeaders
        defaultHTTPHeaders["Accept"] = "application/json"
        return defaultHTTPHeaders
    }()

    static let `default` = PersistentConnection(serverInfo: ServerInfo.default)

    // MARK: Initialization

    init(
        serverInfo: ServerInfo,
        requestMonitor: RequestMonitor = RequestMonitor(),
        startRequestsImmediately: Bool = true,
        trackedConnectionRequestManager: TrackedConnectionRequestManager = .default
        ) {

        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.multipathServiceType = .handover
        self.reachabilityManager = NetworkReachabilityManager(host: "www.apple.com")
        self.requestMonitor = requestMonitor
        self.serverInfo = serverInfo
        self.session = SessionManager(configuration: sessionConfiguration)
        self.session.startRequestsImmediately = startRequestsImmediately
        self.trackedConnectionRequestManager = trackedConnectionRequestManager
        self.reachabilityManager?.listener = { [weak self] in
            guard let `self` = self else { return }

            let status = ConnectionStatus(status: $0)
            let events = self.eventTree.applyChange(status)
            events.forEach({ $0.fireOnQueue(self.callbackQueue) })
        }
        reachabilityManager?.startListening()
    }

    // MARK: Connection

    /// deletes the remote object
    @discardableResult
    func delete(_ path: String, headers: [String: String]) -> ConnectionRequest {
        return connectionRequest(path, method: .delete, headers: headers)
    }

    /// gets the object/s based on the path and parameters
    @discardableResult
    func get(_ path: String, parameters: ConnectionParameters? = nil, headers: [String: String]) -> ConnectionRequest {
        return connectionRequest(path, method: .get, headers: headers, parameters: parameters)
    }

    /// return the value associated to the given header
    func header(forKey key: String) -> String? {
        return defaultHTTPHeaders[key]
    }

    /// observes the reachability changes in the connection
    @discardableResult
    func observeReachabilityStatusChanges(_ callback: @escaping ConnectionStatusChangesCallback) -> EventRegistrationHandle {
        let eventRegistration = DataEventRegistration<ConnectionStatus>(id: eventCounter.getAndIncrement(), callback: callback)
        let connectionStatus: ConnectionStatus = reachabilityManager?.isReachable == true ? .reachable : .notReachable
        callback(connectionStatus)
        eventTree.addEventRegistration(eventRegistration)
        return eventRegistration.id
    }

    /// sends the given action to the host
    @discardableResult
    func send(_ parameters: ConnectionParameters, path: String, action: Action, headers: [String: String]) -> ConnectionRequest {
        let method = HTTPMethod(rawValue: action.rawValue) ?? .post
        return connectionRequest(path, method: method, encoding: JSONEncoding.default, parameters: parameters)
    }

    /// remove the associated header for the given key
    func removeHeader(forKey key: String) {
        defaultHTTPHeaders.removeValue(forKey: key)
    }

    /// remove the associated observer for the given handle
    func removeObserverWithHandle(_ handle: EventRegistrationHandle) {
        let eventRegistration = DataEventRegistration<ConnectionStatus>(id: handle)
        let events = eventTree.removeEventRegistration(eventRegistration, cancelError: nil)
        events.forEach({ $0.fireOnQueue(self.callbackQueue) })
    }

    /// sets a new header
    func setHeader(_ header: String, forKey key: String) {
        defaultHTTPHeaders[key] = header
    }

    // MARK: Private methods

    private func connectionRequest(
        _ path: String,
        method: HTTPMethod,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: [String: String] = [:],
        parameters: ConnectionParameters? = nil
        ) -> ConnectionRequest {

        let headers = defaultHTTPHeaders + headers
        let url = serverInfo.connectionURL().appendingPathComponent(path)
        let dataRequest = session.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
        let connectionRequest = ConnectionRequest(dataRequest: dataRequest, requestMonitor: requestMonitor)
        connectionRequest.delegate = self
        return connectionRequest
    }
}

extension PersistentConnection: ConnectionRequestDelegate {

    // MARK: ConnectionRequestDelegate

    func connectionRequestDidCancel(_ connectionRequest: ConnectionRequest) {
        trackedConnectionRequestManager.setConnectionRequestInactive(connectionRequest)
    }

    func connectionRequestDidFinish(_ connectionRequest: ConnectionRequest) {
        trackedConnectionRequestManager.setConnectionRequestComplete(connectionRequest)
    }

    func connectionRequestDidResume(_ connectionRequest: ConnectionRequest) {
        trackedConnectionRequestManager.setConnectionRequestActive(connectionRequest)
    }

    func connectionRequestDidSuspend(_ connectionRequest: ConnectionRequest) {
        trackedConnectionRequestManager.setConnectionRequestInactive(connectionRequest)
    }
}

