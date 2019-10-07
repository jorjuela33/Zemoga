//
//  CommentDisplayItem.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/6/19.
//

import Domain

struct CommentDisplayItem {
    let body: String
    let comment: Comment

    // MARK: Initializers

    init(comment: Comment) {
        self.body = comment.body
        self.comment = comment
    }
}

extension CommentDisplayItem: Equatable {

    // MARK: Equatable

    static func ==(lhs: CommentDisplayItem, rhs: CommentDisplayItem) -> Bool {
        return lhs.comment == rhs.comment
    }
}
