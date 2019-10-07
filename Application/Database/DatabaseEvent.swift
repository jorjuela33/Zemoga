//
//  DatabaseEvent.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

typealias DataSnapshot<T: DatabaseEntity> = ((Snapshot<T>) -> Void)

enum DatabaseEventType {
    /// listens for all the events and returns
    /// the new data
    case data

    /// listens for deleted values
    case valueDeleted

    /// listens for new values added
    case valueAdded

    /// listens for moved values
    case valueMoved

    /// listens for updated values
    case valueUpdated
}

protocol DatabaseEvent: Event {
    var entityName: String { get }
}

protocol DatabaseEventRegistration: EventRegistration {
    func createEvent<T: DatabaseEntity>(from change: Change<T>, query: DatabaseQuery<T>, changes: [ChangeType]) -> DatabaseEvent
    func respond(to eventType: DatabaseEventType) -> Bool
}

struct DatabaseChildEventRegistration<T: DatabaseEntity>: DatabaseEventRegistration {
    let callbacks: [DatabaseEventType: DataSnapshot<T>]
    let cancelCallback: CancelError?
    let database: Database
    let id: Int64

    // MARK: Initialization

    init(id: Int64, database: Database, callbacks: [DatabaseEventType: DataSnapshot<T>], cancelCallback: CancelError? = nil) {
        self.callbacks = callbacks
        self.cancelCallback = cancelCallback
        self.database = database
        self.id = id
    }

    // MARK: EventRegistration

    func createCancelEvent(from error: Error) -> CancelEvent? {
        guard let _ = cancelCallback else { return nil }

        return CancelEvent(eventRegistration: self, error: error)
    }

    func createEvent<T: DatabaseEntity>(from change: Change<T>, query: DatabaseQuery<T>, changes: [ChangeType]) -> DatabaseEvent {
        let snapshot = Snapshot(value: change.objects, query: query, changes: changes)
        return DatabaseDataEvent(type: change.type, eventRegistration: self, snapshot: snapshot)
    }

    func fireEvent(_ event: Event, queue: DispatchQueue) {
        if
            /// cancel event
            let cancelEvent = event as? CancelEvent,

            /// cancelCallback
            let cancelCallback = cancelCallback, event.isCancelEvent {

            print("Raising cancel value event on \(T.entityName)")
            queue.async {
                cancelCallback(cancelEvent.error)
            }
        } else if let dataEvent = event as? DatabaseDataEvent<T> {
            print("Raising value event on \(dataEvent.snapshot.query)")
            let callback = callbacks[dataEvent.type]
            queue.async {
                callback?(dataEvent.snapshot)
            }
        }
    }

    func matches(_ other: EventRegistration) -> Bool {
        return id == other.id
    }

    func respond(to eventType: DatabaseEventType) -> Bool {
        return callbacks.keys.contains(eventType)
    }
}

struct DatabaseDataEventRegistration<T: DatabaseEntity>: DatabaseEventRegistration {
    let callback: DataSnapshot<T>?
    let cancelCallback: CancelError?
    let database: Database
    let id: Int64

    // MARK: Initialization

    init(id: Int64, database: Database, callback: DataSnapshot<T>? = nil, cancelCallback: CancelError? = nil) {
        self.callback = callback
        self.cancelCallback = cancelCallback
        self.database = database
        self.id = id
    }

    // MARK: EventRegistration

    func createCancelEvent(from error: Error) -> CancelEvent? {
        guard let _ = cancelCallback else {
            return nil
        }

        return CancelEvent(eventRegistration: self, error: error)
    }

    func createEvent<T: DatabaseEntity>(from change: Change<T>, query: DatabaseQuery<T>, changes: [ChangeType]) -> DatabaseEvent {
        let snapshot = Snapshot(value: change.objects, query: query, changes: changes)
        return DatabaseDataEvent(type: .data, eventRegistration: self, snapshot: snapshot)
    }

    func fireEvent(_ event: Event, queue: DispatchQueue) {
        if
            /// cancel event
            let cancelEvent = event as? CancelEvent,

            /// cancelCallback
            let cancelCallback = cancelCallback, event.isCancelEvent {

            print("Raising cancel value event on \(T.entityName)")
            queue.async {
                cancelCallback(cancelEvent.error)
            }
        } else if let dataEvent = event as? DatabaseDataEvent<T> {
            print("Raising value event on \(dataEvent.snapshot.query)")
            queue.async {
                self.callback?(dataEvent.snapshot)
            }
        }
    }

    func matches(_ other: EventRegistration) -> Bool {
        return id == other.id
    }

    func respond(to eventType: DatabaseEventType) -> Bool {
        return eventType == .data
    }
}

class DatabaseDataEvent<T: DatabaseEntity>: DatabaseEvent {
    let eventRegistration: EventRegistration
    let isCancelEvent = false
    let entityName: String
    let snapshot: Snapshot<T>
    let type: DatabaseEventType

    // MARK: Initialization

    init(type: DatabaseEventType, eventRegistration: EventRegistration, snapshot: Snapshot<T>) {
        self.eventRegistration = eventRegistration
        self.entityName = snapshot.query.entityName
        self.snapshot = snapshot
        self.type = type
    }

    // MARK: Event

    func fireOnQueue(_ queue: DispatchQueue) {
        eventRegistration.fireEvent(self, queue: queue)
    }
}
