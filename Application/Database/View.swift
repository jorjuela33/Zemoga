//
//  View.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

struct Change<T: DatabaseEntity> {
    let changesTypes: [ChangeType]
    let objects: [T]
    let type: DatabaseEventType

    // MARK: Initialization

    init(type: DatabaseEventType, objects: [T], changesTypes: [ChangeType]) {
        self.changesTypes = changesTypes
        self.objects = objects
        self.type = type
    }
}

class View<T: DatabaseEntity> {
    private var eventRegistrations: [DatabaseEventRegistration] = []
    private var cachedObjects: [T] = []

    /// true if there is no events
    var isEmpty: Bool {
        return eventRegistrations.isEmpty
    }

    let query: DatabaseQuery<T>

    // MARK: Initializers

    init(query: DatabaseQuery<T>, initialCachedObjects: [T]) {
        self.cachedObjects = initialCachedObjects
        self.query = query
    }

    // MARK: Instance methods

    /// adds a new event into the stack.
    func addEventRegistration(_ eventRegistration: DatabaseEventRegistration) {
        eventRegistrations.append(eventRegistration)
    }

    /// apply the changes into the cached objects and
    /// generates new events
    func applyChanges(_ changes: [ChangeType], entities: [T], forQuery query: DatabaseQuery<T>) -> [DatabaseEvent] {
        var deletetions: [ChangeType] = []
        var insertions: [ChangeType] = []
        var moves: [ChangeType] = []
        var updates: [ChangeType] = []

        for change in changes {
            switch change {
            case .delete: deletetions.append(change)
            case .insert: insertions.append(change)
            case .move: moves.append(change)
            case .update: updates.append(change)
            }
        }

        self.cachedObjects = entities
        var events: [DatabaseEvent] = []

        if !deletetions.isEmpty {
            let deletionChange = Change(type: .valueDeleted, objects: cachedObjects, changesTypes: deletetions)
            events += generateEvents(of: .valueDeleted, change: deletionChange, eventRegistrations: eventRegistrations)
        }

        if !insertions.isEmpty {
            let insertionChange = Change(type: .valueAdded, objects: cachedObjects, changesTypes: insertions)
            events += generateEvents(of: .valueAdded, change: insertionChange, eventRegistrations: eventRegistrations)
        }

        if !moves.isEmpty {
            let moveChange = Change(type: .valueMoved, objects: cachedObjects, changesTypes: moves)
            events += generateEvents(of: .valueMoved, change: moveChange, eventRegistrations: eventRegistrations)
        }

        if !updates.isEmpty {
            let updateChange = Change(type: .valueUpdated, objects: cachedObjects, changesTypes: updates)
            events += generateEvents(of: .valueUpdated, change: updateChange, eventRegistrations: eventRegistrations)
        }

        let dataChange = Change(type: .data, objects: cachedObjects, changesTypes: changes)
        events += generateEvents(of: .data, change: dataChange, eventRegistrations: eventRegistrations)
        return events
    }

    /// the list of the initial events.
    func initialEvents(for eventRegistration: DatabaseEventRegistration) -> [DatabaseEvent] {
        guard !cachedObjects.isEmpty else {
            return []
        }

        let change = Change(type: .data, objects: cachedObjects, changesTypes: [])
        return generateEvents(of: .data, change: change, eventRegistrations: [eventRegistration])
    }

    /// remove all callbacks related to the event registration.
    func removeEventRegistration(_ eventRegistration: DatabaseEventRegistration, withCancelError error: Error?) -> [CancelEvent] {
        var cancelEvents: [CancelEvent] = []
        if let error = error {
            for eventRegistration in eventRegistrations {
                if let cancelEvent = eventRegistration.createCancelEvent(from: error) {
                    cancelEvents.append(cancelEvent)
                }
            }
        }

        eventRegistrations = eventRegistrations.filter({ !$0.matches(eventRegistration) })
        return cancelEvents
    }

    // MARK: Private methods

    private func generateEvents(
        of eventType: DatabaseEventType,
        change: Change<T>,
        eventRegistrations: [DatabaseEventRegistration]
        ) -> [DatabaseEvent] {

        var events: [DatabaseEvent] = []
        for eventRegistration in eventRegistrations where eventRegistration.respond(to: eventType) {
            let event = eventRegistration.createEvent(from: change, query: query, changes: [])
            events.append(event)
        }

        return events
    }
}

