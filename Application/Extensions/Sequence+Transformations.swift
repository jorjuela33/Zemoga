//
//  Sequence+Transformations.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

extension Sequence where Iterator.Element: DomainTypeConvertible {
    typealias Element = Iterator.Element

    func mapToDomain() -> [Element.DomainType] {
        return map {
            return $0.asDomain()
        }
    }
}
