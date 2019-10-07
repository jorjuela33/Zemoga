//
//  Comment.swift
//  Domain
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

public struct Comment {
    public let id: Int64
    public let body: String
    public let email: String
    public let name: String
    public let postID: Int64

    // MARK: Initializers

    public init(id: Int64, body: String, email: String, name: String, postID: Int64) {
        self.id = id
        self.body = body
        self.email = email
        self.name = name
        self.postID = postID
    }
}

extension Comment: Equatable {

    // MARK: Equatable

    public static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.id == rhs.id &&
               lhs.body == rhs.body &&
               lhs.email == rhs.email &&
               lhs.name == rhs.name &&
               lhs.postID == rhs.postID
    }
}
