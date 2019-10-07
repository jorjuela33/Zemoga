//
//  Observer.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import Foundation

class Observer: NSObject {
    private var callback: (Any?, [NSKeyValueChangeKey: Any]?, NSValue) -> Void
    private var cancellationToken: Int32 = 0

    let keyPath: String
    weak var object: NSObject?
    let options: NSKeyValueObservingOptions

    var token: NSValue {
        return NSValue(pointer: &callback)
    }

    // MARK: Initialization

    init(
        object: NSObject,
        keyPath: String,
        options: NSKeyValueObservingOptions,
        callback: @escaping (Any?, [NSKeyValueChangeKey: Any]?, NSValue) -> Void
        ) {

        self.callback = callback
        self.keyPath = keyPath
        self.object = object
        self.options = options
    }

    // MARK: Instance methods

    func invalidate() {
        if OSAtomicCompareAndSwap32(0, 1, &cancellationToken) {
            object?.removeObserver(self, forKeyPath: keyPath)
            object = nil
        }
    }

    func startObserving() {
        object?.addObserver(self, forKeyPath: keyPath, options: options, context: nil)
    }

    // MARK: Observer methods

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
        ) {

        guard cancellationToken == 0 else { return }

        callback(object, change, token)
    }
}
