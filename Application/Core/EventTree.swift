//
//  EventTree.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

class EventTree {
    private let queue = DispatchQueue(label: "com.event.tree.queue")
    private var events: [Int64: EventRegistration] = [:]

    /// true if the tree is empty
    var isEmpty: Bool {
        return events.isEmpty
    }

    /// returns the existing event for the given registration
    subscript<T: EventRegistration>(key: Int64) -> T? {
        return events[key] as? T
    }

    // MARK: Instance methods

    /// adds a new event into the tree
    func addEventRegistration(_ eventRegistration: EventRegistration) {
         queue.sync {
            events[eventRegistration.id] = eventRegistration
        }
    }

    /// apply the new changes for all the events into the tree
    func applyChange<T>(_ change: T) -> [Event] {
        return queue.sync {
            return self.events.values.compactMap({ $0 as? DataEventRegistration<T> }).map({ $0.createEvent(from: change) })
        }
    }

    /// apply the new changes into tree for the event registration
    /// matching the given registration id
    func applyChange<T>(_ change: T, forEventRegistration registration: EventRegistrationHandle) -> [Event] {
        return queue.sync {
            guard let eventRegistration: DataEventRegistration<T> = self[registration] else {
                return []
            }

            return [eventRegistration.createEvent(from: change)]
        }
    }

    /// remove the given event registration from the view
    func removeEventRegistration(_ eventRegistration: EventRegistration, cancelError: Error?) -> [Event] {
        return queue.sync {
            guard let eventRegistration = self.events[eventRegistration.id] else {
                return []
            }

            self.events.removeValue(forKey: eventRegistration.id)

            if
                /// error
                let error = cancelError,

                /// cancel event
                let cancelEvent = eventRegistration.createCancelEvent(from: error) {

                return [cancelEvent]
            }

            return []
        }
    }
}
