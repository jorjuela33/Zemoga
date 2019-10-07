//
//  TrackedConnectionRequestManager.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

class TrackedConnectionRequestManager {
    private typealias TrackedConnectionRequestEntry = [Int64: TrackedConnectionRequest]

    private var connectionID: Int64 = 0
    private let queue = DispatchQueue(label: "com.app.trackedConnectionRequestManager")
    private var trackedConnectionRequestTree: [String: TrackedConnectionRequestEntry] = [:]

    static let `default` = TrackedConnectionRequestManager()

    // MARK: Instance methods

    func setConnectionRequestActive(_ connectionRequest: ConnectionRequest) {
        setConnectionRequestActive(true, connectionRequest: connectionRequest)
    }

    func setConnectionRequestComplete(_ connectionRequest: ConnectionRequest) {
        guard
            /// tracked connection request
            let trackedConnectionRequest = findTrackedConnectionRequest(for: connectionRequest),

            /// path
            let path = connectionRequest.url?.path, !trackedConnectionRequest.isComplete else {
                return
        }

        let newTrackedConnectionRequest = trackedConnectionRequest.setComplete()
        cacheTrackedConnectionRequest(newTrackedConnectionRequest, forPath: path)
    }

    func setConnectionRequestInactive(_ connectionRequest: ConnectionRequest) {
        setConnectionRequestActive(false, connectionRequest: connectionRequest)
    }

    // MARK: Private methods

    private func cacheTrackedConnectionRequest(_ trackedConnectionRequest: TrackedConnectionRequest, forPath path: String) {
        var trackedConnectionRequestEntry = trackedConnectionRequestTree[path] ?? [:]
        trackedConnectionRequestEntry[trackedConnectionRequest.connectionRequest.identifier] = trackedConnectionRequest
        trackedConnectionRequestTree[path] = trackedConnectionRequestEntry
    }

    private func findTrackedConnectionRequest(for connectionRequest: ConnectionRequest) -> TrackedConnectionRequest? {
        guard let path = connectionRequest.url?.path else { return nil }

        let trackedConnectionEntry = trackedConnectionRequestTree[path]
        return trackedConnectionEntry?[connectionRequest.identifier]
    }

    private func prune(_ connectionRequest: ConnectionRequest, forPath path: String) {
        guard let trackedConnectionEntries = trackedConnectionRequestTree[path] else { return }

        trackedConnectionRequestTree[path] = trackedConnectionEntries.filter({ $0.key != connectionRequest.identifier })
    }

    private func setConnectionRequestActive(_ active: Bool, connectionRequest: ConnectionRequest) {
        queue.sync {
            guard let path = connectionRequest.url?.path else { return }

            let lastUse = Date().timeIntervalSince1970
            if let trackedConnectionRequest = self.findTrackedConnectionRequest(for: connectionRequest) {
                let newTrackedConnectionRequest = trackedConnectionRequest.updateLastUse(lastUse).setIsActive(active)
                self.cacheTrackedConnectionRequest(newTrackedConnectionRequest, forPath: path)
            } else {
                let trackedConnection = TrackedConnectionRequest(
                    id: self.connectionID + 1,
                    connectionRequest: connectionRequest,
                    isActive: active,
                    lastUse: lastUse
                )
                self.cacheTrackedConnectionRequest(trackedConnection, forPath: path)
            }
        }
    }
}

extension TrackedConnectionRequestManager: CustomStringConvertible {

    // MARK: CustomStringConvertible

    var description: String {
        let trackedConnectionRequestEntries = trackedConnectionRequestTree.values.flatMap({ $0.values })
        let completedRequests = trackedConnectionRequestEntries.filter({ $0.isComplete }).count
        let activeRequests = trackedConnectionRequestEntries.filter({ !$0.isComplete && $0.isActive }).count
        let inactiveRequests = trackedConnectionRequestEntries.filter({ !$0.isComplete && !$0.isActive }).count
        return """
        Completed requests: \(completedRequests)
        Active requests: \(activeRequests)
        Inactive requests: \(inactiveRequests)
        Total requests: \(trackedConnectionRequestTree.values.count)
        """
    }
}
