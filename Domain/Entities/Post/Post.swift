//
//  Post.swift
//  Domain
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Foundation

public struct Post {
    public let id: Int64
    public let body: String
    public let isFavorite: Bool
    public let read: Bool
    public let title: String
    public let userID: Int64

    // MARK: Initializers

    public init(id: Int64, body: String, isFavorite: Bool, read: Bool, title: String, userID: Int64) {
        self.id = id
        self.body = body
        self.isFavorite = isFavorite
        self.read = read
        self.title = title
        self.userID = userID
    }
}

extension Post: Equatable {

    // MARK: Equatable

    public static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id &&
               lhs.body == rhs.body &&
               lhs.isFavorite == rhs.isFavorite &&
               lhs.read == rhs.read &&
               lhs.title == rhs.title &&
               lhs.userID == rhs.userID
    }
}
