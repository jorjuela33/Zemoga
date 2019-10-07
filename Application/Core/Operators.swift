//
//  Operators.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

func +<T>(lhs: [String: T], rhs: [String: T]) -> [String: T] {
    return lhs.merging(rhs, uniquingKeysWith: { _, value in return value })
}
