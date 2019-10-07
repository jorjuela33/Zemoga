//
//  Protocols.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

protocol DomainTypeConvertible {
    associatedtype DomainType

    func asDomain() -> DomainType
}
