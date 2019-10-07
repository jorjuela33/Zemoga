//
//  TrackedConnectionRequest.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

struct TrackedConnectionRequest {
    let connectionRequest: ConnectionRequest
    let id: Int64
    let isActive: Bool
    let isComplete: Bool
    let lastUse: TimeInterval

    // MARK: Initialization

    init(id: Int64, connectionRequest: ConnectionRequest, isActive: Bool, isComplete: Bool = false, lastUse: TimeInterval) {
        self.connectionRequest = connectionRequest
        self.id = id
        self.isActive = isActive
        self.isComplete = isComplete
        self.lastUse = lastUse
    }

    // MARK: Instance methods

    func setIsActive(_ isActive: Bool) -> TrackedConnectionRequest {
        return TrackedConnectionRequest(
            id: id,
            connectionRequest: connectionRequest,
            isActive: isActive,
            isComplete: isComplete,
            lastUse: lastUse
        )
    }

    func setComplete() -> TrackedConnectionRequest {
        return TrackedConnectionRequest(
            id: id,
            connectionRequest: connectionRequest,
            isActive: isActive,
            isComplete: true,
            lastUse: lastUse
        )
    }

    func updateLastUse(_ lastUse: TimeInterval) -> TrackedConnectionRequest {
        return TrackedConnectionRequest(
            id: id,
            connectionRequest: connectionRequest,
            isActive: isActive,
            isComplete: isComplete,
            lastUse: lastUse
        )
    }
}

extension TrackedConnectionRequest: Equatable {

    // MARK: Equatable

    static func ==(lhs: TrackedConnectionRequest, rhs: TrackedConnectionRequest) -> Bool {
        return lhs.connectionRequest == rhs.connectionRequest &&
               lhs.id == rhs.id &&
               lhs.isComplete == rhs.isComplete &&
               lhs.lastUse == rhs.lastUse
    }
}
