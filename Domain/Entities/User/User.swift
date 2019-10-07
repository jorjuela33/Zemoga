//
//  User.swift
//  Domain
//
//  Created by Jorge Orjuela on 10/5/19.
//

import Foundation

public struct User {
    public let id: Int64
    public let email: String
    public let name: String
    public let phone: String
    public let website: String

   // MARK: Initializers

    public init(id: Int64, email: String, name: String, phone: String, website: String) {
        self.id = id
        self.email = email
        self.name = name
        self.phone = phone
        self.website = website
    }
}
