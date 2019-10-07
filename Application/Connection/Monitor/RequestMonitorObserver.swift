//
//  RequestMonitorObserver.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

class RequestMonitorObserver {
    typealias RequestMonitorCallback = ((RequestMonitorState) -> Void)

    private var callback: RequestMonitorCallback?

    let connectionRequest: ConnectionRequest

    // MARK: Initialization

    init(connectionRequest: ConnectionRequest, callback: @escaping RequestMonitorCallback) {
        self.connectionRequest = connectionRequest
        self.callback = callback
    }

    // MARK: Instance methods

    func notify(_ newState: RequestMonitorState) {
        callback?(newState)
    }
}

extension RequestMonitorObserver: Hashable {

    // MARK: Hashable

    static func ==(lhs: RequestMonitorObserver, rhs: RequestMonitorObserver) -> Bool {
        return lhs.connectionRequest.identifier == rhs.connectionRequest.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(connectionRequest.identifier.hashValue)
    }
}
