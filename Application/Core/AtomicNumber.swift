//
//  AtomicNumber.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

class AtomicNumber {
    private var number: Int64 = 0
    private let lock = NSLock()

    static let `default` = AtomicNumber()

    // MARK: Instance methods

    func current() -> Int64 {
        lock.lock()
        defer { lock.unlock() }
        return number
    }

    func getAndIncrement() -> Int64 {
        let result = number
        OSAtomicIncrement64(&number)
        return result
    }
}
