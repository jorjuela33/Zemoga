//
//  PostDisplayItem.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import Domain

struct PostDisplayItem {
    let body: String
    let post: Post
    let read: Bool

    // MARK: Initializers

    init(post: Post) {
        self.body = post.body
        self.post = post
        self.read = post.read
    }
}

extension PostDisplayItem: Equatable {

    // MARK: Equatable

    static func ==(lhs: PostDisplayItem, rhs: PostDisplayItem) -> Bool {
        return lhs.post == rhs.post
    }
}
