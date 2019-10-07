//
//  RequestMonitor.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Alamofire

enum RequestMonitorState {
    case canceled
    case finished
    case resumed
    case suspended
}

class RequestMonitor {
    private let lock = NSLock()
    private var observers: [RequestMonitorObserver] = []
    private let queue = DispatchQueue(label: "com.kisi.requestMonitor")

    // MARK: Initialization

    init(notificationCenter: NotificationCenter = .default) {
        notificationCenter.addObserver(
            self,
            selector: #selector(didReceiveRequestDidCancelNotification(_:)),
            name: Notification.Name.Task.DidCancel,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(didReceiveRequestDidFinishNotification(_:)),
            name: Notification.Name.Task.DidComplete,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(didReceiveRequestDidResumeNotification(_:)),
            name: Notification.Name.Task.DidResume,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(didReceiveRequestDidSuspendNotification(_:)),
            name: Notification.Name.Task.DidSuspend,
            object: nil
        )
    }

    // MARK: Intance methods

    func subscribeToStateUpdates(
        _ connectionRequest: ConnectionRequest,
        callback: @escaping RequestMonitorObserver.RequestMonitorCallback
        ) {

        queue.sync {
            let observer = RequestMonitorObserver(connectionRequest: connectionRequest, callback: callback)
            observers.append(observer)
        }
    }

    // MARK: Notification methods

    @objc
    func didReceiveRequestDidCancelNotification(_ notification: Notification) {
        guard let request = notification.object as? Request else { return }

        notify(request, newState: .canceled)
        removeObserver(for: request)
    }

    @objc
    func didReceiveRequestDidFinishNotification(_ notification: Notification) {
        guard
            /// session delegate
            let sessionDelegate = notification.object as? SessionDelegate,

            /// session task
            let task = notification.userInfo?[Notification.Key.Task] as? URLSessionTask,

            /// request
            let request = sessionDelegate[task] else { return }

        notify(request, newState: .finished)
        removeObserver(for: request)
    }

    @objc
    func didReceiveRequestDidResumeNotification(_ notification: Notification) {
        guard let request = notification.object as? Request else { return }

        notify(request, newState: .resumed)
    }

    @objc
    func didReceiveRequestDidSuspendNotification(_ notification: Notification) {
        guard let request = notification.object as? Request else { return }

        notify(request, newState: .suspended)
    }

    // MARK: Private methods

    private func notify(_ request: Request, newState state: RequestMonitorState) {
        lock.lock()
        let observers = self.observers.filter({ $0.connectionRequest.matches(request) })
        lock.unlock()
        observers.forEach({ $0.notify(state) })
    }

    private func removeObserver(for request: Request) {
        lock.lock()
        observers = observers.filter({ !$0.connectionRequest.matches(request) })
        lock.unlock()
    }
}
