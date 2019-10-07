//
//  CommentEntity.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Domain

struct CommentEntity: Codable {
    let id: Int64
    let body: String
    let email: String
    let name: String
    let postID: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case body
        case email
        case name
        case postID = "postId"
    }
}

extension CommentEntity: DatabaseEntity {

    // MARK: DatabaseEntity

    static var entityName: String {
        return "Comment"
    }

    static func map(from entity: CommentManagedObject) -> CommentEntity {
        return CommentEntity(id: entity.id, body: entity.body, email: entity.email, name: entity.name, postID: entity.postID)
    }

    func update(_ entity: CommentManagedObject) {
        entity.id = id
        entity.body = body
        entity.email = email
        entity.name = name
        entity.postID = postID
    }
}

extension CommentEntity: DomainTypeConvertible {

    // MARK: DomainTypeConvertible

    func asDomain() -> Comment {
        return Comment(id: id, body: body, email: email, name: name, postID: postID)
    }
}

