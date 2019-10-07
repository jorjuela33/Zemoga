//
//  ConnectionTree.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

class ConnectionTree {
    private let queue = DispatchQueue(label: "com.connections.tree.queue")
    private var connections: [ConnectionRequestRegistration: ConnectionRequest] = [:]

    /// true if no requests are in progress
    var isEmpty: Bool {
        return connections.isEmpty
    }

    // MARK: Instance methods

    func addConnectionRequest(_ connectionRequest: ConnectionRequest) {
        queue.sync {
            self.connections[connectionRequest.identifier] = connectionRequest
        }
    }

    func removeConnectionRequest(withRegistration registration: ConnectionRequestRegistration) -> ConnectionRequest? {
        return queue.sync {
            return self.connections.removeValue(forKey: registration)
        }
    }
}
