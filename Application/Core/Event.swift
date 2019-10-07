//
//  Event.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

typealias CancelError = ((Error) -> Void)
typealias EventRegistrationHandle = Int64

protocol Event {
    var isCancelEvent: Bool { get }

    func fireOnQueue(_ queue: DispatchQueue)
}

protocol EventRegistration {
    var id: EventRegistrationHandle { get }

    func createCancelEvent(from error: Error) -> CancelEvent?
    func fireEvent(_ event: Event, queue: DispatchQueue)
    func matches(_ other: EventRegistration) -> Bool
}

class CancelEvent: Event {
    private let eventRegistration: EventRegistration

    let error: Error
    let isCancelEvent = true

    // MARK: Initializers

    init(eventRegistration: EventRegistration, error: Error) {
        self.error = error
        self.eventRegistration = eventRegistration
    }

    // MARK: Event

    func fireOnQueue(_ queue: DispatchQueue) {
        eventRegistration.fireEvent(self, queue: queue)
    }
}

struct DataEvent<T>: Event {
    let eventRegistration: EventRegistration
    let isCancelEvent = false
    let value: T

    // MARK: Initialization

    init(eventRegistration: EventRegistration, value: T) {
        self.eventRegistration = eventRegistration
        self.value = value
    }

    // MARK: Event

    func fireOnQueue(_ queue: DispatchQueue) {
        eventRegistration.fireEvent(self, queue: queue)
    }
}

struct DataEventRegistration<T>: EventRegistration {
    typealias DataEventRegistrationCallback = (T) -> Void

    let callback: DataEventRegistrationCallback?
    let cancelCallback: CancelError?
    let id: EventRegistrationHandle

    // MARK: Initialization

    init(id: EventRegistrationHandle, callback: DataEventRegistrationCallback? = nil, cancelCallback: CancelError? = nil) {
        self.callback = callback
        self.cancelCallback = cancelCallback
        self.id = id
    }

    // MARK: EventRegistration

    func createCancelEvent(from error: Error) -> CancelEvent? {
        guard let _ = cancelCallback else { return nil }

        return CancelEvent(eventRegistration: self, error: error)
    }

    func createEvent(from change: T) -> Event {
        return DataEvent(eventRegistration: self, value: change)
    }

    func fireEvent(_ event: Event, queue: DispatchQueue) {
        if
            /// cancel event
            let cancelEvent = event as? CancelEvent,

            /// cancelCallback
            let cancelCallback = cancelCallback, event.isCancelEvent {

            print("Raising cancel value event for regitration event handle \(id)")
            queue.async {
                cancelCallback(cancelEvent.error)
            }
        } else if let dataEvent = event as? DataEvent<T> {
            print("Raising value event on \(dataEvent.eventRegistration.id)")
            queue.async {
                self.callback?(dataEvent.value)
            }
        }
    }

    func matches(_ other: EventRegistration) -> Bool {
        return id == other.id
    }
}
