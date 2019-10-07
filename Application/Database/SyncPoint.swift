//
//  SyncPoint.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

class SyncPoint {
    private let queue = DispatchQueue(label: "com.sync.point.queue")
    private var views: [AnyHashable: Any] = [:]

    /// returns the existing view for the given query
    subscript<T: DatabaseEntity>(key: DatabaseQuery<T>) -> View<T>? {
        return views[key] as? View<T>
    }

    // MARK: Instance methods

    /// adds a new event into the view if exists. if there is no view
    /// a new one is created.
    func addEventRegistration<T: DatabaseEntity>(
        _ eventRegistration: DatabaseEventRegistration,
        forQuery query: DatabaseQuery<T>
        ) -> [DatabaseEvent] {

        return queue.sync {
            let view = views[query] as? View<T> ?? View(query: query, initialCachedObjects: [])
            view.addEventRegistration(eventRegistration)
            views[query] = view
            return view.initialEvents(for: eventRegistration)
        }
    }

    /// apply the new changes into the view
    func applyChanges<T: DatabaseEntity>(_ changes: [ChangeType], entities: [T], forQuery query: DatabaseQuery<T>) -> [DatabaseEvent] {
        return queue.sync {
            guard let view = views[query] as? View<T> else {
                return []
            }

            return view.applyChanges(changes, entities: entities, forQuery: query)
        }
    }

    /// remove the given event registration from the view
    func removeEventRegistration<T: DatabaseEntity>(
        _ eventRegistration: DatabaseEventRegistration,
        forQuery query: DatabaseQuery<T>,
        cancelError: Error?
        ) -> [CancelEvent] {

        return queue.sync {
            guard let view = self[query] else {
                return []
            }

            let events = view.removeEventRegistration(eventRegistration, withCancelError: cancelError)
            if view.isEmpty {
                self.views.removeValue(forKey: query)
            }

            return events
        }
    }
}
